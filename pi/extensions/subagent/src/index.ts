/**
 * Generic subagent tool: runs a self-contained task in a separate `pi` process
 * with a fresh context window and returns only its final report.
 */
import { homedir } from "node:os";
import { resolve } from "node:path";
import { StringEnum } from "@earendil-works/pi-ai";
import { getMarkdownTheme, type ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Container, Markdown, Spacer, Text } from "@earendil-works/pi-tui";
import { Type } from "typebox";
import { PersistentAgents } from "./persistent.js";
import { CHILD_ENV, emptyResult, mapWithConcurrency, READ_ONLY_TOOLS, runTask, truncate, type TaskResult, type TaskSpec, type TraceItem, type Usage } from "./runner.js";

const MAX_TASKS = 8;
const CONCURRENCY = 4;
const COLLAPSED_TRACE = 8;

interface Details {
  mode: "single" | "parallel";
  results: TaskResult[];
}

const AccessSchema = StringEnum(["read-only", "full"] as const, {
  description: `"read-only" (default): ${READ_ONLY_TOOLS.join(", ")}, for research, review and verification. "full": can edit files and use every tool except subagent.`,
  default: "read-only",
});
const taskFields = {
  description: Type.String({ description: "Short label (3-8 words) shown to the user." }),
  task: Type.String({ description: "Complete, self-contained instructions: goal, relevant paths and constraints, and what the final report must contain. The subagent sees nothing else." }),
  access: Type.Optional(AccessSchema),
  model: Type.Optional(Type.String({ description: "provider/model to use. Omit to use the current model and thinking level." })),
  cwd: Type.Optional(Type.String({ description: "Working directory. Defaults to the current one." })),
};
const Params = Type.Object({
  description: Type.Optional(taskFields.description),
  task: Type.Optional(taskFields.task),
  access: taskFields.access,
  model: taskFields.model,
  cwd: taskFields.cwd,
  tasks: Type.Optional(Type.Array(Type.Object(taskFields), {
    description: `Independent tasks to run in parallel instead of a single task (max ${MAX_TASKS}, ${CONCURRENCY} at a time).`,
  })),
});

const failed = (result: TaskResult) => result.status === "failed" || result.status === "aborted";

type Fg = (color: any, text: string) => string;

function formatTokens(count: number): string {
  if (count < 1000) return String(count);
  if (count < 10_000) return `${(count / 1000).toFixed(1)}k`;
  if (count < 1_000_000) return `${Math.round(count / 1000)}k`;
  return `${(count / 1_000_000).toFixed(1)}M`;
}

function formatUsage(usage: Usage, model?: string): string {
  const parts: string[] = [];
  if (usage.turns) parts.push(`${usage.turns} turn${usage.turns > 1 ? "s" : ""}`);
  if (usage.input) parts.push(`↑${formatTokens(usage.input)}`);
  if (usage.output) parts.push(`↓${formatTokens(usage.output)}`);
  if (usage.cacheRead) parts.push(`R${formatTokens(usage.cacheRead)}`);
  if (usage.cost) parts.push(`$${usage.cost.toFixed(4)}`);
  if (usage.contextTokens) parts.push(`ctx:${formatTokens(usage.contextTokens)}`);
  if (model) parts.push(model);
  return parts.join(" ");
}

function totalUsage(results: TaskResult[]): Usage {
  const total: Usage = { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, cost: 0, contextTokens: 0, turns: 0 };
  for (const { usage } of results) {
    total.input += usage.input; total.output += usage.output; total.cacheRead += usage.cacheRead;
    total.cacheWrite += usage.cacheWrite; total.cost += usage.cost; total.turns += usage.turns;
  }
  return total;
}

function formatCall(item: TraceItem, fg: Fg): string {
  const home = homedir();
  const short = (value: unknown) => {
    const text = String(value ?? ".");
    return text.startsWith(home) ? `~${text.slice(home.length)}` : text;
  };
  const { args } = item;
  switch (item.tool) {
    case "bash": return fg("muted", "$ ") + fg("toolOutput", String(args.command ?? "…").split("\n")[0].slice(0, 80));
    case "read": return fg("muted", "read ") + fg("accent", short(args.path ?? args.file_path));
    case "write": case "edit": return fg("muted", `${item.tool} `) + fg("accent", short(args.path ?? args.file_path));
    case "ls": return fg("muted", "ls ") + fg("accent", short(args.path));
    case "find": case "grep":
      return fg("muted", `${item.tool} `) + fg("accent", String(args.pattern ?? "")) + fg("dim", ` in ${short(args.path)}`);
    default: {
      const preview = JSON.stringify(args);
      return fg("accent", item.tool) + fg("dim", ` ${preview.length > 60 ? `${preview.slice(0, 60)}…` : preview}`);
    }
  }
}

function icon(result: TaskResult, fg: Fg): string {
  if (result.status === "running") return fg("warning", "⏳");
  return failed(result) ? fg("error", "✗") : fg("success", "✓");
}

function traceLines(result: TaskResult, fg: Fg, limit?: number): string[] {
  const items = limit ? result.trace.slice(-limit) : result.trace;
  const hidden = result.traceOmitted + result.trace.length - items.length;
  return [
    ...(hidden > 0 ? [fg("muted", `… ${hidden} earlier tool calls`)] : []),
    ...items.map((item) => fg("muted", "→ ") + formatCall(item, fg)),
  ];
}

function resultText(result: TaskResult): string {
  if (!failed(result)) return truncate(result.output || "(no output)");
  return truncate(`${result.error ?? "Subagent failed."}${result.output ? `\n\nLast output:\n${result.output}` : ""}`);
}

export default function subagentExtension(pi: ExtensionAPI): void {
  // Subagents cannot start subagents (also excluded with --tools/--exclude-tools).
  if (process.env[CHILD_ENV]) return;

  const agents = new PersistentAgents();
  // Session changes/reload tear down the extension runtime; never leak children.
  pi.on("session_shutdown", () => agents.closeAll());

  pi.registerTool({
    name: "subagent_session",
    label: "Persistent agent",
    description: "Manage persistent subagents, each with its own conversation memory. Spawn a named persona, send messages repeatedly to its agentId, inspect list/history, or close it. Agents do not see the parent or each other: explicitly forward replies to orchestrate communication. Memory lasts until close or parent session shutdown/reload, not across restarts. Child agents cannot ask for confirmation. Use subagent for independent one-shot tasks.",
    promptSnippet: "Use subagent_session to orchestrate named agents that retain context across messages",
    parameters: Type.Object({
      action: StringEnum(["spawn", "send", "list", "history", "close"] as const),
      agentId: Type.Optional(Type.String({ description: "Agent identifier. Optional at spawn; required for send/history/close." })),
      persona: Type.Optional(Type.String({ description: "Stable role/instructions, required at spawn." })),
      message: Type.Optional(Type.String({ description: "Message to this agent, required for send." })),
      access: taskFields.access,
      model: taskFields.model,
      cwd: taskFields.cwd,
      offset: Type.Optional(Type.Integer({ minimum: 0, description: "History message offset (default 0)." })),
      limit: Type.Optional(Type.Integer({ minimum: 1, maximum: 100, description: "History page size (default 20)." })),
    }),
    executionMode: "parallel",
    async execute(_id, params, signal, onUpdate, ctx) {
      const textResult = (data: unknown) => ({
        content: [{ type: "text" as const, text: truncate(JSON.stringify(data, null, 2)) }],
        details: { action: params.action, data },
      });
      if (signal?.aborted) throw new Error("Persistent agent operation was aborted.");
      if (params.action === "spawn") {
        if (!params.persona?.trim()) throw new Error("spawn requires persona.");
        return textResult(await agents.spawn({ id: params.agentId, persona: params.persona, access: params.access, model: params.model, cwd: params.cwd }, {
          cwd: ctx.cwd,
          model: ctx.model ? `${ctx.model.provider}/${ctx.model.id}` : undefined,
          thinkingLevel: ctx.thinkingLevel,
        }, signal));
      }
      if (params.action === "list") return textResult(agents.list());
      if (!params.agentId) throw new Error(`${params.action} requires agentId.`);
      if (params.action === "close") {
        await agents.close(params.agentId);
        return textResult({ agentId: params.agentId, closed: true });
      }
      if (params.action === "history") return textResult(await agents.history(params.agentId, params.offset, params.limit ?? 20));
      if (!params.message?.trim()) throw new Error("send requires a nonempty message.");
      const report = await agents.send(params.agentId, params.message, signal, partial => {
        onUpdate?.({ content: [{ type: "text", text: partial.output || "(running…)" }], details: { mode: "single", results: [partial] } });
      });
      return { content: [{ type: "text", text: resultText(report) }], details: { mode: "single", results: [report] }, usage: report.modelUsage, isError: failed(report) };
    },
    renderCall(args, theme) {
      return new Text(theme.fg("toolTitle", theme.bold("agent ")) + theme.fg("accent", `${args.action ?? "…"} ${args.agentId ?? ""}`), 0, 0);
    },
    renderResult(result, _options, _theme) {
      const first = result.content[0];
      return new Text(first?.type === "text" ? first.text : "(no output)", 0, 0);
    },
  });

  pi.on("tool_result", (event) => {
    if (event.toolName !== "subagent") return;
    const details = event.details as Details | undefined;
    if (details?.results.length && details.results.every(failed)) return { isError: true };
  });

  pi.registerTool({
    name: "subagent",
    label: "Subagent",
    description: [
      "Run a task in a separate agent with its own fresh context window. Only its final report is returned,",
      "which keeps exploration out of your context and keeps independent work (for example, writing and reviewing) from influencing each other.",
      "The subagent cannot see this conversation: put everything it needs in `task`.",
      "Use `tasks` to run independent tasks in parallel. Subagents cannot ask the user anything,",
      "so commands that normally require confirmation are blocked; do those yourself.",
    ].join(" "),
    promptSnippet: "Delegate a self-contained task to a subagent with a fresh context window",
    parameters: Params,
    executionMode: "parallel",

    async execute(_id, params, signal, onUpdate, ctx) {
      const dispatch = {
        cwd: ctx.cwd,
        model: ctx.model ? `${ctx.model.provider}/${ctx.model.id}` : undefined,
        thinkingLevel: ctx.thinkingLevel,
      };
      const specs: TaskSpec[] = params.tasks?.length ? params.tasks : params.task ? [{
        description: params.description ?? "Subagent task", task: params.task,
        access: params.access, model: params.model, cwd: params.cwd,
      }] : [];
      if (!specs.length || (params.tasks?.length && params.task)) throw new Error("Provide either `task` or `tasks`.");
      if (specs.length > MAX_TASKS) throw new Error(`Too many parallel tasks (${specs.length}); the maximum is ${MAX_TASKS}.`);
      for (const spec of specs) spec.cwd = spec.cwd ? resolve(ctx.cwd, spec.cwd) : undefined;

      const mode: Details["mode"] = params.tasks?.length ? "parallel" : "single";
      const results = specs.map(emptyResult);
      const update = () => {
        const done = results.filter((result) => result.status !== "running").length;
        onUpdate?.({
          content: [{ type: "text", text: mode === "single" ? results[0].output || "(running…)" : `${done}/${results.length} done` }],
          details: { mode, results: [...results] },
        });
      };
      await mapWithConcurrency(specs, CONCURRENCY, async (spec, index) => {
        results[index] = await runTask(spec, dispatch, signal, (partial) => { results[index] = partial; update(); });
        update();
      });
      if (signal?.aborted) throw new Error("Subagent was aborted.");

      const details: Details = { mode, results };
      if (mode === "single") return { content: [{ type: "text", text: resultText(results[0]) }], details };
      const succeeded = results.filter((result) => !failed(result)).length;
      const sections = results.map((result) => `### [${result.description}] ${failed(result) ? result.status : "done"}\n\n${resultText(result)}`);
      return { content: [{ type: "text", text: `${succeeded}/${results.length} subagents succeeded\n\n${sections.join("\n\n---\n\n")}` }], details };
    },

    renderCall(args, theme) {
      const fg: Fg = theme.fg.bind(theme);
      const title = fg("toolTitle", theme.bold("subagent "));
      if (args.tasks?.length) {
        const lines = args.tasks.slice(0, 4).map((task) => `  ${fg("accent", task.description ?? "…")}${fg("dim", ` [${task.access ?? "read-only"}]`)}`);
        if (args.tasks.length > 4) lines.push(`  ${fg("muted", `… +${args.tasks.length - 4} more`)}`);
        return new Text([title + fg("accent", `parallel (${args.tasks.length})`), ...lines].join("\n"), 0, 0);
      }
      return new Text(title + fg("accent", args.description ?? "…") + fg("dim", ` [${args.access ?? "read-only"}]`), 0, 0);
    },

    renderResult(result, { expanded }, theme) {
      const fg: Fg = theme.fg.bind(theme);
      const details = result.details as Details | undefined;
      if (!details?.results.length) {
        const first = result.content[0];
        return new Text(first?.type === "text" ? first.text : "(no output)", 0, 0);
      }
      const markdown = getMarkdownTheme();
      const container = new Container();
      const single = details.mode === "single";
      if (!single) {
        const done = details.results.filter((item) => item.status !== "running").length;
        const ok = details.results.filter((item) => item.status === "done").length;
        container.addChild(new Text(fg("accent", done < details.results.length ? `${done}/${details.results.length} done` : `${ok}/${details.results.length} succeeded`), 0, 0));
      }
      for (const item of details.results) {
        if (!single) container.addChild(new Spacer(1));
        let header = `${icon(item, fg)} ${fg("toolTitle", theme.bold(item.description))}`;
        if (failed(item)) header += ` ${fg("error", item.error ?? item.status)}`;
        container.addChild(new Text(header, 0, 0));
        if (expanded) container.addChild(new Text(fg("muted", "Task: ") + fg("dim", item.task), 0, 0));
        const lines = traceLines(item, fg, expanded ? undefined : single ? COLLAPSED_TRACE : 3);
        if (lines.length) container.addChild(new Text(lines.join("\n"), 0, 0));
        if (expanded && item.output) {
          container.addChild(new Spacer(1));
          container.addChild(new Markdown(item.output.trim(), 0, 0, markdown));
        }
        const usage = formatUsage(item.usage, item.model);
        if (usage) container.addChild(new Text(fg("dim", usage), 0, 0));
      }
      if (!single && details.results.every((item) => item.status !== "running")) {
        container.addChild(new Spacer(1));
        container.addChild(new Text(fg("dim", `Total: ${formatUsage(totalUsage(details.results))}`), 0, 0));
      }
      if (!expanded) container.addChild(new Text(fg("muted", "(Ctrl+O to expand)"), 0, 0));
      return container;
    },
  });
}

