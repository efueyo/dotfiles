import { spawn } from "node:child_process";
import { existsSync } from "node:fs";
import { mkdtemp, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { basename, join } from "node:path";

/** Set in child processes so they never register the subagent tool themselves. */
export const CHILD_ENV = "PI_SUBAGENT";
export const READ_ONLY_TOOLS = ["read", "grep", "find", "ls", "bash"];
export const OUTPUT_CAP = 50 * 1024;
// Linux rejects single arguments over 128 KiB; the task is passed as one.
export const TASK_CAP = 100 * 1024;
const TRACE_CAP = 200;
const STDERR_CAP = 8 * 1024;

export type Access = "read-only" | "full";

export interface TaskSpec {
  description: string;
  task: string;
  access?: Access;
  model?: string;
  cwd?: string;
}

export interface Usage {
  input: number;
  output: number;
  cacheRead: number;
  cacheWrite: number;
  cost: number;
  contextTokens: number;
  turns: number;
}

/** A tool call made by the child, with long argument values shortened for display. */
export interface TraceItem {
  tool: string;
  args: Record<string, unknown>;
}

/**
 * Kept in tool result details, which pi persists in the parent session. Only a
 * compact trace is stored, never the child's tool outputs.
 */
export interface TaskResult {
  description: string;
  task: string;
  access: Access;
  status: "running" | "done" | "failed" | "aborted";
  output: string;
  error?: string;
  trace: TraceItem[];
  traceOmitted: number;
  usage: Usage;
  model?: string;
}

export interface Dispatch {
  cwd: string;
  /** Parent's model and thinking level, used when a task does not name a model. */
  model?: string;
  thinkingLevel?: string;
  /** Overrides how pi is started (tests). */
  invocation?: (args: string[]) => { command: string; args: string[] };
}

export function systemPrompt(access: Access): string {
  return [
    "You are a subagent: a separate agent started by another agent to complete one delegated task in a fresh context.",
    "- You cannot see the other agent's conversation. The task is everything you know; rely on it and on what you can find yourself.",
    "- No user is available. Do not ask questions or wait for confirmation; make reasonable assumptions and state them.",
    "- Stay within the task's scope.",
    ...(access === "read-only" ? ["- You are read-only: do not modify files. Use bash only to inspect."] : []),
    "- Finish with a concise final report: what you found or changed, with file paths (and line numbers where useful), and anything unresolved. Only that final message is returned.",
  ].join("\n");
}

export function emptyResult(spec: TaskSpec): TaskResult {
  return {
    description: spec.description, task: spec.task, access: spec.access ?? "read-only", status: "running",
    output: "", trace: [], traceOmitted: 0,
    usage: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, cost: 0, contextTokens: 0, turns: 0 },
  };
}

export function truncate(text: string, cap = OUTPUT_CAP): string {
  const bytes = Buffer.byteLength(text, "utf8");
  if (bytes <= cap) return text;
  const kept = Buffer.from(text, "utf8").subarray(0, cap).toString("utf8").replace(/�$/, "");
  return `${kept}\n\n[Output truncated: ${bytes - Buffer.byteLength(kept, "utf8")} bytes omitted.]`;
}

function shorten(args: unknown): Record<string, unknown> {
  if (!args || typeof args !== "object") return {};
  return Object.fromEntries(Object.entries(args).map(([key, value]) => [key,
    typeof value === "string" ? (value.length > 200 ? `${value.slice(0, 200)}…` : value)
      : value === null || typeof value !== "object" ? value : "[…]"]));
}

export function defaultInvocation(args: string[]): { command: string; args: string[] } {
  // Re-run the same pi entry point (and runtime) as the parent when possible.
  const script = process.argv[1];
  if (script && !script.startsWith("/$bunfs/root/") && existsSync(script)) return { command: process.execPath, args: [script, ...args] };
  if (!/^(node|bun)(\.exe)?$/i.test(basename(process.execPath))) return { command: process.execPath, args };
  return { command: "pi", args };
}

interface ChildMessage {
  role?: string;
  content?: { type?: string; text?: string; name?: string; arguments?: unknown }[];
  usage?: { input?: number; output?: number; cacheRead?: number; cacheWrite?: number; totalTokens?: number; cost?: { total?: number } };
  model?: string;
  stopReason?: string;
  errorMessage?: string;
}

export async function runTask(
  spec: TaskSpec, dispatch: Dispatch, signal: AbortSignal | undefined, onUpdate?: (result: TaskResult) => void,
): Promise<TaskResult> {
  const result = emptyResult(spec);
  const fail = (error: string) => { result.status = "failed"; result.error = error; return result; };
  if (Buffer.byteLength(spec.task, "utf8") > TASK_CAP) {
    return fail(`Task exceeds ${TASK_CAP / 1024} KiB. Write the context to a file and reference its path in the task.`);
  }
  const args = ["--mode", "json", "-p", "--no-session"];
  const model = spec.model ?? dispatch.model;
  if (model) args.push("--model", model);
  if (!spec.model && dispatch.thinkingLevel) args.push("--thinking", dispatch.thinkingLevel);
  if (result.access === "read-only") args.push("--tools", READ_ONLY_TOOLS.join(","));
  else args.push("--exclude-tools", "subagent");
  result.model = model;

  const directory = await mkdtemp(join(tmpdir(), "pi-subagent-"));
  try {
    const promptPath = join(directory, "system-prompt.md");
    await writeFile(promptPath, systemPrompt(result.access), { mode: 0o600 });
    // "Task:" prefix keeps pi from reading a task that starts with "@" as a file input.
    args.push("--append-system-prompt", promptPath, "--", `Task:\n${spec.task}`);
    const invocation = (dispatch.invocation ?? defaultInvocation)(args);
    let stderr = "";
    let aborted = false;
    const exitCode = await new Promise<number>((resolve) => {
      const child = spawn(invocation.command, invocation.args, {
        cwd: spec.cwd ?? dispatch.cwd, shell: false, stdio: ["ignore", "pipe", "pipe"],
        env: { ...process.env, [CHILD_ENV]: "1" },
      });
      let buffer = "";
      const handle = (line: string) => {
        let event: { type?: string; message?: ChildMessage };
        try { event = JSON.parse(line); } catch { return; }
        const message = event.message;
        if (event.type !== "message_end" || message?.role !== "assistant") return;
        result.usage.turns++;
        const usage = message.usage;
        if (usage) {
          result.usage.input += usage.input ?? 0;
          result.usage.output += usage.output ?? 0;
          result.usage.cacheRead += usage.cacheRead ?? 0;
          result.usage.cacheWrite += usage.cacheWrite ?? 0;
          result.usage.cost += usage.cost?.total ?? 0;
          result.usage.contextTokens = usage.totalTokens ?? result.usage.contextTokens;
        }
        if (message.model) result.model = message.model;
        const text = (message.content ?? []).filter((part) => part.type === "text" && part.text).map((part) => part.text).join("\n\n");
        if (text) result.output = text;
        for (const part of message.content ?? []) {
          if (part.type !== "toolCall") continue;
          result.trace.push({ tool: String(part.name ?? "tool"), args: shorten(part.arguments) });
          if (result.trace.length > TRACE_CAP) { result.trace.shift(); result.traceOmitted++; }
        }
        if (message.stopReason === "error") result.error = message.errorMessage ?? "The model returned an error.";
        if (message.stopReason === "aborted") aborted = true;
        onUpdate?.(result);
      };
      child.stdout.on("data", (chunk: Buffer) => {
        buffer += chunk.toString();
        const lines = buffer.split("\n");
        buffer = lines.pop() ?? "";
        for (const line of lines) if (line.trim()) handle(line);
      });
      child.stderr.on("data", (chunk: Buffer) => {
        if (stderr.length < STDERR_CAP) stderr = (stderr + chunk.toString()).slice(0, STDERR_CAP);
      });
      child.on("error", (error) => { stderr ||= error.message; resolve(1); });
      child.on("close", (code) => {
        if (buffer.trim()) handle(buffer);
        resolve(code ?? 1);
      });
      if (signal) {
        const kill = () => {
          aborted = true;
          child.kill("SIGTERM");
          setTimeout(() => { if (child.exitCode === null && child.signalCode === null) child.kill("SIGKILL"); }, 5000).unref();
        };
        if (signal.aborted) kill();
        else signal.addEventListener("abort", kill, { once: true });
        child.once("close", () => signal.removeEventListener("abort", kill));
      }
    });
    if (aborted) { result.status = "aborted"; result.error = "Subagent was aborted."; }
    else if (result.error) result.status = "failed";
    else if (exitCode !== 0) fail(stderr.trim() || `Subagent exited with code ${exitCode}.`);
    else result.status = "done";
    return result;
  } finally {
    await rm(directory, { recursive: true, force: true });
  }
}

export async function mapWithConcurrency<T, R>(items: T[], limit: number, run: (item: T, index: number) => Promise<R>): Promise<R[]> {
  const results = new Array<R>(items.length);
  let next = 0;
  await Promise.all(Array.from({ length: Math.min(limit, items.length) }, async () => {
    while (next < items.length) {
      const index = next++;
      results[index] = await run(items[index], index);
    }
  }));
  return results;
}
