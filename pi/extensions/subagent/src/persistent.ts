import { randomUUID } from "node:crypto";
import { mkdtemp, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import type { Usage as ModelUsage } from "@earendil-works/pi-ai";
import { getPackageDir, RpcClient, type RpcClientOptions, type JsonAgentSessionEvent } from "@earendil-works/pi-coding-agent";
import { CHILD_ENV, READ_ONLY_TOOLS, TASK_CAP, emptyResult, truncate,
  type Access, type Dispatch, type TaskResult } from "./runner.js";

export interface SpawnSpec { id?: string; persona: string; access?: Access; model?: string; cwd?: string }
export interface AgentInfo {
  id: string; persona: string; access: Access; model?: string; cwd: string;
  status: "starting" | "idle" | "running" | "failed" | "closed";
}
export type PersistentResult = TaskResult & { modelUsage: ModelUsage };
export type PersistentClient = Pick<RpcClient, "start" | "stop" | "abort" | "onEvent" | "promptAndWait" | "getMessages">;
export type ClientFactory = (options: RpcClientOptions) => PersistentClient;
export interface PersistentOptions { clientFactory?: ClientFactory; maxAgents?: number; timeoutMs?: number }
const DEFAULT_TIMEOUT = 10 * 60 * 1000;
const cancelled = () => new Error("Persistent agent was aborted or closed.");

/** A bounded, cancellation-aware wait. The losing promise always has a rejection handler. */
function wait<T>(work: Promise<T>, timeout: number, signal?: AbortSignal): Promise<T> {
  return new Promise((accept, reject) => {
    const abort = () => finish(cancelled());
    const timer = setTimeout(() => finish(new Error("Persistent agent timed out.")), timeout);
    const finish = (error?: unknown, value?: T) => {
      clearTimeout(timer); signal?.removeEventListener("abort", abort);
      if (error) reject(error); else accept(value as T);
    };
    work.then(value => finish(undefined, value), finish);
    signal?.addEventListener("abort", abort, { once: true });
    if (signal?.aborted) abort();
  });
}

/**
 * RpcClient 0.84's collector outlives rejected prompts and does not notice exits.
 * Own the completion listener/deadline instead, including handled prompts and
 * a health check for a child that exits after acknowledging the prompt.
 */
export class ManagedRpcClient extends RpcClient {
  private cancelWait?: () => void;
  private awaitingAcceptance = false;
  override async abort(): Promise<void> {
    // Pi may still be awaiting asynchronous input handlers when abort arrives.
    // In that window abort() can acknowledge an idle session, then start the
    // canceled prompt later. Stop the process rather than risk executing it.
    if (this.awaitingAcceptance) {
      await this.stop();
      throw new Error("Canceled before prompt acceptance; agent stopped. Spawn a replacement.");
    }
    await super.abort();
    this.cancelWait?.();
  }
  override async start(): Promise<void> {
    await super.start();
    // start() only waits 100ms; a state response confirms CLI initialization.
    await wait(this.getState(), 30000);
  }
  override async promptAndWait(message: string, images?: Parameters<RpcClient["promptAndWait"]>[1], timeout = DEFAULT_TIMEOUT): Promise<JsonAgentSessionEvent[]> {
    return new Promise((accept, reject) => {
      let finished = false;
      let checking = false;
      const finish = (error?: unknown) => {
        if (finished) return;
        finished = true; clearTimeout(timer); clearInterval(heartbeat); unsubscribe(); this.cancelWait = undefined;
        if (error) reject(error); else accept([]); // Results are aggregated by the caller's event listener.
      };
      const unsubscribe = this.onEvent(event => { if (event.type === "agent_settled") finish(); });
      const timer = setTimeout(() => finish(new Error("Persistent agent timed out.")), timeout);
      const heartbeat = setInterval(() => {
        if (checking) return;
        checking = true;
        void wait(this.getState(), 5000).then(() => { checking = false; }, finish);
      }, 1000);
      this.cancelWait = () => finish(cancelled());
      // Older Pi versions return void; newer ones return a disposition.
      this.awaitingAcceptance = true;
      void this.prompt(message, images).then(disposition => {
        this.awaitingAcceptance = false;
        if ((disposition as unknown) === "handled") finish();
      }, error => { this.awaitingAcceptance = false; finish(error); });
    });
  }
  override async stop(): Promise<void> { this.cancelWait?.(); await super.stop(); }
}

interface Entry {
  info: AgentInfo; client?: PersistentClient; directory?: string; ready: Promise<void>;
  queue: Promise<unknown>; lifetime: AbortController; closing?: Promise<void>; stopped?: Promise<void>;
}

/** In-memory conversations, each owned by one long-lived RPC subprocess. */
export class PersistentAgents {
  private readonly entries = new Map<string, Entry>();
  private readonly factory: ClientFactory;
  private readonly maxAgents: number;
  private readonly timeout: number;
  private closingAll?: Promise<void>;
  constructor(options: PersistentOptions | ClientFactory = {}) {
    const config = typeof options === "function" ? { clientFactory: options } : options;
    this.factory = config.clientFactory ?? (options => new ManagedRpcClient(options));
    this.maxAgents = config.maxAgents ?? 8;
    this.timeout = config.timeoutMs ?? DEFAULT_TIMEOUT;
    if (!Number.isInteger(this.maxAgents) || this.maxAgents < 1 || !Number.isFinite(this.timeout) || this.timeout <= 0) throw new Error("Invalid persistent agent limits.");
  }

  async spawn(spec: SpawnSpec, dispatch: Dispatch, signal?: AbortSignal): Promise<AgentInfo> {
    if (this.closingAll) throw new Error("Persistent agents are closing.");
    const id = spec.id ?? randomUUID();
    if (!/^[a-zA-Z0-9][a-zA-Z0-9_-]{0,63}$/.test(id)) throw new Error("Invalid agent identifier (use 1–64 letters, digits, underscores or hyphens).");
    if (this.entries.has(id)) throw new Error(`Agent '${id}' already exists.`);
    if (this.entries.size >= this.maxAgents) throw new Error(`Persistent agent limit (${this.maxAgents}) reached.`);
    if (!spec.persona.trim() || Buffer.byteLength(spec.persona) > TASK_CAP) throw new Error("Persona must be nonempty and at most 100 KiB.");
    if (spec.access && spec.access !== "read-only" && spec.access !== "full") throw new Error("Invalid agent access.");
    const info: AgentInfo = { id, persona: spec.persona, access: spec.access ?? "read-only",
      model: spec.model ?? dispatch.model, cwd: resolve(dispatch.cwd, spec.cwd ?? "."), status: "starting" };
    const entry: Entry = { info, ready: Promise.resolve(), queue: Promise.resolve(), lifetime: new AbortController() };
    this.entries.set(id, entry); // Reserve before any asynchronous startup work.
    const abort = () => entry.lifetime.abort();
    signal?.addEventListener("abort", abort, { once: true });
    if (signal?.aborted) abort();
    entry.ready = (async () => {
      try {
        if (entry.lifetime.signal.aborted) throw cancelled();
        entry.directory = await mkdtemp(join(tmpdir(), "pi-persistent-agent-"));
        const promptPath = join(entry.directory, "system-prompt.md");
        await writeFile(promptPath, [
          "You are a persistent subagent with your own conversation history. Use prior messages when relevant.",
          "You cannot see the parent or other agents' conversations unless their messages are explicitly forwarded to you.",
          "No user is available. Do not ask questions or wait for confirmation. Stay within the delegated task's scope.",
          ...(info.access === "read-only" ? ["You are read-only: do not modify files. Use bash only to inspect."] : []),
          "Finish each task with a concise report. Only the current task's final reply is returned to the parent.",
          `Persona:\n${spec.persona}\n`,
        ].join("\n"), { mode: 0o600 });
        if (entry.lifetime.signal.aborted) throw cancelled();
        const args = ["--no-session", "--append-system-prompt", promptPath];
        if (!spec.model && dispatch.thinkingLevel) args.push("--thinking", dispatch.thinkingLevel);
        if (info.access === "read-only") args.push("--tools", READ_ONLY_TOOLS.join(","));
        else args.push("--exclude-tools", "subagent,subagent_session");
        // Pi remaps SDK imports to the host's package when loading extensions.
        // import.meta.resolve() can still resolve this extension's older dev
        // dependency, causing a newer RpcClient to spawn an incompatible CLI.
        // Resolve through the SAME SDK instance that supplies RpcClient.
        const cliPath = join(getPackageDir(), "dist", "cli.js");
        entry.client = this.factory({ cliPath, cwd: info.cwd, model: info.model, args, env: { [CHILD_ENV]: "1" } });
        const startup = entry.client.start();
        // A late startup completion after cancellation must not leak a process.
        void startup.then(async () => { if (entry.lifetime.signal.aborted) await entry.client?.stop(); }, () => {}).catch(() => {});
        await wait(startup, 30000, entry.lifetime.signal);
        info.status = "idle";
      } catch (error) {
        entry.lifetime.abort(); info.status = "failed";
        try { await this.dispose(entry); }
        finally { if (this.entries.get(id) === entry) this.entries.delete(id); }
        throw error;
      } finally { signal?.removeEventListener("abort", abort); }
    })();
    await entry.ready;
    return { ...info };
  }

  list(): AgentInfo[] { return [...this.entries.values()].map(entry => ({ ...entry.info })); }
  private get(id: string): Entry {
    const entry = this.entries.get(id);
    if (!entry) throw new Error(`Unknown persistent agent '${id}'.`);
    return entry;
  }
  private enqueue<T>(entry: Entry, operation: () => Promise<T>): Promise<T> {
    const work = entry.queue.then(operation);
    entry.queue = work.catch(() => {});
    return work;
  }
  private usable(entry: Entry): PersistentClient {
    if (entry.lifetime.signal.aborted || entry.info.status === "failed") throw new Error(`Persistent agent '${entry.info.id}' is ${entry.info.status}; close it and spawn a replacement.`);
    if (!entry.client || entry.info.status === "starting") throw new Error(`Persistent agent '${entry.info.id}' is not ready.`);
    return entry.client;
  }

  async send(id: string, message: string, signal?: AbortSignal, onUpdate?: (result: TaskResult) => void): Promise<PersistentResult> {
    const entry = this.get(id);
    const result: PersistentResult = { ...emptyResult({ description: id, task: message, access: entry.info.access }), modelUsage: {
      input: 0, output: 0, cacheRead: 0, cacheWrite: 0, totalTokens: 0,
      cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, total: 0 },
    } };
    result.model = entry.info.model;
    if (Buffer.byteLength(message) > TASK_CAP) { result.status = "failed"; result.error = "Message exceeds 100 KiB. Write context to a file and reference it."; return result; }
    let started = false;
    const queued = this.enqueue(entry, async () => {
      started = true;
      if (signal?.aborted) { result.status = "aborted"; result.error = "Persistent agent was aborted."; return result; }
      let unsubscribe = () => {};
      const combined = AbortSignal.any([entry.lifetime.signal, ...(signal ? [signal] : [])]);
      let client: PersistentClient | undefined;
      try {
        client = this.usable(entry); entry.info.status = "running";
        unsubscribe = client.onEvent(event => {
          if (event.type !== "message_end" || event.message.role !== "assistant") return;
          const msg = event.message;
          result.usage.turns++;
          if (msg.usage) {
            for (const key of ["input", "output", "cacheRead", "cacheWrite"] as const) result.usage[key] += msg.usage[key] ?? 0;
            for (const key of ["input", "output", "cacheRead", "cacheWrite", "totalTokens"] as const) result.modelUsage[key] += msg.usage[key] ?? 0;
            for (const key of ["input", "output", "cacheRead", "cacheWrite", "total"] as const) result.modelUsage.cost[key] += msg.usage.cost?.[key] ?? 0;
            result.usage.cost += msg.usage.cost?.total ?? 0;
            result.usage.contextTokens = msg.usage.totalTokens ?? result.usage.contextTokens;
          }
          if (msg.model) result.model = msg.model;
          result.output = truncate(msg.content.filter(part => part.type === "text").map(part => part.text).join("\n\n"));
          for (const part of msg.content) {
            if (part.type !== "toolCall") continue;
            const args = Object.fromEntries(Object.entries(part.arguments ?? {}).slice(0, 50).map(([key, value]) => [key.slice(0, 200),
              typeof value === "string" ? value.slice(0, 200) : value && typeof value === "object" ? "[…]" : value]));
            result.trace.push({ tool: part.name.slice(0, 200), args });
            if (result.trace.length > 200) { result.trace.shift(); result.traceOmitted++; }
          }
          // Only the latest turn's terminal reason is authoritative after retries.
          result.error = msg.stopReason === "error" ? msg.errorMessage ?? "The model returned an error." : undefined;
          result.status = msg.stopReason === "aborted" ? "aborted" : "running";
          try { onUpdate?.(structuredClone(result)); } catch { /* UI callbacks cannot corrupt the conversation. */ }
        });
        await wait(client.promptAndWait(`Task:\n${message}`, undefined, this.timeout), this.timeout, combined);
        result.status = result.status === "aborted" ? "aborted" : result.error ? "failed" : "done";
      } catch (error) {
        result.status = combined.aborted ? "aborted" : "failed";
        result.error = error instanceof Error ? error.message : String(error);
        if (client && combined.aborted && !entry.lifetime.signal.aborted) {
          try { await wait(client.abort(), 1000); }
          catch { entry.info.status = "failed"; await this.dispose(entry); }
        } else if (client && !combined.aborted) { entry.info.status = "failed"; await this.dispose(entry); }
      } finally {
        unsubscribe();
        if (entry.info.status === "running") entry.info.status = "idle";
      }
      if (result.status === "aborted") result.error ??= "Persistent agent was aborted.";
      return result;
    });
    if (!signal) return queued;
    // A canceled queued message need not wait for the earlier task's deadline.
    return new Promise<PersistentResult>((accept, reject) => {
      const abortQueued = () => {
        if (started) return; // Active sends handle cancellation through RPC abort.
        result.status = "aborted"; result.error = "Persistent agent was aborted.";
        accept(structuredClone(result));
      };
      signal.addEventListener("abort", abortQueued, { once: true });
      if (signal.aborted) abortQueued();
      queued.then(value => { signal.removeEventListener("abort", abortQueued); accept(value); }, error => { signal.removeEventListener("abort", abortQueued); reject(error); });
    });
  }

  async history(id: string, offset = 0, limit?: number): Promise<{ messages: unknown[]; total: number }> {
    if (!Number.isInteger(offset) || offset < 0 || (limit !== undefined && (!Number.isInteger(limit) || limit < 0))) throw new Error("History offset and limit must be nonnegative integers.");
    const entry = this.get(id);
    return this.enqueue(entry, async () => {
      const client = this.usable(entry);
      try {
        const messages = await wait(client.getMessages(), 30000, entry.lifetime.signal);
        return { messages: messages.slice(offset, limit === undefined ? undefined : offset + limit), total: messages.length };
      } catch (error) {
        if (!entry.lifetime.signal.aborted) { entry.info.status = "failed"; await this.dispose(entry); }
        throw error;
      }
    });
  }

  private dispose(entry: Entry): Promise<void> {
    return entry.stopped ??= (async () => {
      try { if (entry.client) await wait(entry.client.stop(), 3000); }
      finally { if (entry.directory) await rm(entry.directory, { recursive: true, force: true }); }
    })();
  }
  async close(id: string): Promise<void> {
    const entry = this.entries.get(id);
    if (!entry) return;
    if (entry.closing) return entry.closing;
    entry.info.status = "closed"; entry.lifetime.abort();
    entry.closing = (async () => {
      try { await entry.ready.catch(() => {}); await this.dispose(entry); await entry.queue; }
      finally { if (this.entries.get(id) === entry) this.entries.delete(id); }
    })();
    return entry.closing;
  }
  closeAll(): Promise<void> {
    if (this.closingAll) return this.closingAll;
    this.closingAll = Promise.allSettled([...this.entries.keys()].map(id => this.close(id))).then(results => {
      const failed = results.find(result => result.status === "rejected");
      if (failed?.status === "rejected") throw failed.reason;
    }).finally(() => { this.closingAll = undefined; });
    return this.closingAll;
  }
}
