import assert from "node:assert/strict";
import { access, readFile, stat } from "node:fs/promises";
import { dirname, isAbsolute } from "node:path";
import { fileURLToPath } from "node:url";
import test from "node:test";
import { getPackageDir, type JsonAgentSessionEvent, type RpcClientOptions } from "@earendil-works/pi-coding-agent";
import { join } from "node:path";
import { ManagedRpcClient, PersistentAgents, type PersistentClient } from "./persistent.js";
import { TASK_CAP } from "./runner.js";

function deferred<T = void>() {
  let resolve!: (value: T) => void;
  let reject!: (error: Error) => void;
  const promise = new Promise<T>((yes, no) => { resolve = yes; reject = no; });
  return { promise, resolve, reject };
}
const tick = () => new Promise<void>(resolve => setImmediate(resolve));
class FakeClient implements PersistentClient {
  listeners = new Set<(event: JsonAgentSessionEvent) => void>();
  messages: unknown[] = [];
  calls: string[] = [];
  active = false;
  stopped = 0;
  aborted = 0;
  deadline?: number;
  startGate?: ReturnType<typeof deferred<void>>;
  startError?: Error;
  pending?: ReturnType<typeof deferred<JsonAgentSessionEvent[]>>;
  async start() { if (this.startError) throw this.startError; await this.startGate?.promise; }
  async stop() { this.stopped++; this.active = false; this.pending?.reject(new Error("Process stopped")); }
  async abort() {
    this.aborted++; this.active = false;
    this.pending?.reject(new Error("Aborted"));
  }
  onEvent(listener: (event: JsonAgentSessionEvent) => void) { this.listeners.add(listener); return () => { this.listeners.delete(listener); }; }
  emit(text: string, reason = "stop", tools = 0) {
    const message = { role: "assistant", model: "actual", stopReason: reason, errorMessage: reason === "error" ? "Provider failed" : undefined,
      content: [{ type: "text", text }, ...Array.from({ length: tools }, (_, i) => ({ type: "toolCall", id: String(i), name: "read", arguments: { path: "x".repeat(1000), nested: { secret: true } } }))],
      usage: { input: 10, output: 2, cacheRead: 3, cacheWrite: 4, totalTokens: 19, cost: { total: 0.01 } } };
    this.messages.push(message);
    for (const listener of this.listeners) listener({ type: "message_end", message } as JsonAgentSessionEvent);
  }
  complete(text: string, reason = "stop", tools = 0) {
    this.emit(text, reason, tools); this.active = false; this.pending!.resolve([]);
  }
  async promptAndWait(message: string, _images?: Parameters<PersistentClient["promptAndWait"]>[1], timeout?: number) {
    assert.equal(this.active, false, "overlapping prompts");
    this.active = true; this.calls.push(message); this.deadline = timeout;
    this.messages.push({ role: "user", content: message });
    this.pending = deferred<JsonAgentSessionEvent[]>();
    return this.pending.promise;
  }
  async getMessages(): ReturnType<PersistentClient["getMessages"]> {
    assert.equal(this.active, false, "history raced an active prompt");
    return structuredClone(this.messages) as Awaited<ReturnType<PersistentClient["getMessages"]>>;
  }
}
function setup(options: { maxAgents?: number; timeoutMs?: number } = {}, make = () => new FakeClient()) {
  const clients: FakeClient[] = [];
  const configs: RpcClientOptions[] = [];
  const agents = new PersistentAgents({ ...options, clientFactory(config) { configs.push(config); const client = make(); clients.push(client); return client; } });
  return { agents, clients, configs };
}
const dispatch = { cwd: process.cwd(), model: "provider/parent", thinkingLevel: "high" };

test("spawn has no prompt, resolves cwd and inherits model/thinking; prompt files cleaned", async () => {
  const { agents, clients, configs } = setup();
  try {
    const info = await agents.spawn({ id: "reader", persona: "Review code", cwd: "src" }, dispatch);
    assert.equal(info.status, "idle"); assert.equal(info.access, "read-only");
    assert.equal(info.cwd, `${dispatch.cwd}/src`);
    assert.equal(clients[0].calls.length, 0);
    assert.equal(configs[0].env?.PI_SUBAGENT, "1");
    assert.ok(isAbsolute(configs[0].cliPath!));
    assert.equal(configs[0].cliPath, join(getPackageDir(), "dist", "cli.js"), "CLI and RpcClient must come from the same SDK instance, not import.meta.resolve");
    assert.equal(configs[0].model, dispatch.model);
    assert.deepEqual(configs[0].args?.slice(-4), ["--thinking", "high", "--tools", "read,grep,find,ls,bash"]);
    const args = configs[0].args!;
    const path = args[args.indexOf("--append-system-prompt") + 1];
    const prompt = await readFile(path, "utf8");
    assert.match(prompt, /persistent subagent[\s\S]*Review code/);
    assert.doesNotMatch(prompt, /fresh context|task is everything you know/);
    assert.equal((await stat(path)).mode & 0o777, 0o600);
    agents.list()[0].status = "failed"; assert.equal(agents.list()[0].status, "idle");
    await agents.close("reader"); await assert.rejects(access(dirname(path)));
    await agents.close("reader"); assert.equal(clients[0].stopped, 1);
    await agents.spawn({ persona: "Writer", access: "full", model: "override" }, dispatch);
    assert.equal(configs[1].model, "override"); assert.ok(!configs[1].args?.includes("--thinking"));
    assert.deepEqual(configs[1].args?.slice(-2), ["--exclude-tools", "subagent,subagent_session"]);
  } finally { await agents.closeAll(); }
});

test("retains conversation history and per-send usage without mixing agents", async () => {
  const { agents, clients } = setup();
  try {
    await agents.spawn({ id: "a", persona: "A" }, dispatch);
    await agents.spawn({ id: "b", persona: "B" }, dispatch);
    const first = agents.send("a", "remember"); await tick(); clients[0].complete("remembered");
    assert.equal((await first).usage.input, 10);
    const second = agents.send("a", "recall"); await tick();
    clients[0].emit("thinking", "toolUse", 1); clients[0].complete("remembered again");
    const result = await second;
    assert.equal(result.output, "remembered again"); assert.equal(result.usage.turns, 2); assert.equal(result.usage.input, 20);
    assert.equal(result.modelUsage.input, 20); assert.equal(result.modelUsage.cost.total, 0.02);
    assert.equal(result.model, "actual"); assert.equal(result.trace.length, 1);
    const history = await agents.history("a", 1, 2);
    assert.equal(history.total, 5); assert.equal(history.messages.length, 2);
    assert.equal((await agents.history("b")).total, 0);
    assert.equal((await agents.history("a", 0, 0)).messages.length, 0);
    await assert.rejects(agents.history("a", -1), /nonnegative/);
  } finally { await agents.closeAll(); }
});

test("same-agent sends and history are FIFO, separate agents run in parallel", async () => {
  const { agents, clients } = setup();
  try {
    for (const id of ["a", "b"]) await agents.spawn({ id, persona: id }, dispatch);
    const a1 = agents.send("a", "first");
    const history = agents.history("a");
    const a2 = agents.send("a", "second");
    const b1 = agents.send("b", "parallel");
    await tick(); assert.equal(clients[0].calls.length, 1); assert.equal(clients[1].calls.length, 1);
    clients[1].complete("B"); assert.equal((await b1).output, "B");
    clients[0].complete("A1"); await a1;
    assert.equal((await history).total, 2);
    await tick(); assert.equal(clients[0].calls.length, 2);
    clients[0].complete("A2"); assert.equal((await a2).output, "A2");
  } finally { await agents.closeAll(); }
});

test("cancellation interrupts active RPC and allows subsequent tasks", async () => {
  const { agents, clients } = setup();
  try {
    await agents.spawn({ id: "a", persona: "A" }, dispatch);
    const controller = new AbortController();
    const pending = agents.send("a", "blocked", controller.signal); await tick(); controller.abort();
    assert.equal((await pending).status, "aborted"); assert.equal(clients[0].aborted, 1);
    assert.equal(agents.list()[0].status, "idle"); assert.equal(clients[0].listeners.size, 0);
    const next = agents.send("a", "next"); await tick(); clients[0].complete("OK"); assert.equal((await next).status, "done");
    const aborted = new AbortController(); aborted.abort();
    assert.equal((await agents.send("a", "never prompted", aborted.signal)).status, "aborted");
    assert.equal(clients[0].calls.length, 2);
  } finally { await agents.closeAll(); }
});

test("queued cancellation returns promptly without sending the canceled prompt", async () => {
  const { agents, clients } = setup();
  try {
    await agents.spawn({ id: "a", persona: "A" }, dispatch);
    const active = agents.send("a", "active"); await tick();
    const controller = new AbortController();
    const queued = agents.send("a", "canceled", controller.signal); controller.abort();
    assert.equal((await queued).status, "aborted"); assert.equal(clients[0].active, true);
    clients[0].complete("done"); await active; await tick();
    assert.equal(clients[0].calls.length, 1);
  } finally { await agents.closeAll(); }
});

test("default registry cap is eight; pre-aborted spawn does not allocate a client", async () => {
  const { agents, clients } = setup();
  try {
    const abort = new AbortController(); abort.abort();
    await assert.rejects(agents.spawn({ persona: "A" }, dispatch, abort.signal), /aborted/);
    assert.equal(clients.length, 0);
    for (let i = 0; i < 8; i++) await agents.spawn({ id: `a${i}`, persona: "A" }, dispatch);
    await assert.rejects(agents.spawn({ persona: "A" }, dispatch), /limit \(8\)/);
  } finally { await agents.closeAll(); }
});

test("terminal model errors and aborts cannot return stale text; recovered retries succeed", async () => {
  const { agents, clients } = setup();
  try {
    await agents.spawn({ id: "a", persona: "A" }, dispatch);
    const old = agents.send("a", "old"); await tick(); clients[0].complete("old answer"); await old;
    const failed = agents.send("a", "fail"); await tick(); clients[0].complete("", "error");
    const result = await failed; assert.equal(result.status, "failed"); assert.equal(result.output, ""); assert.equal(result.error, "Provider failed");
    const aborted = agents.send("a", "abort"); await tick(); clients[0].complete("", "aborted"); assert.equal((await aborted).status, "aborted");
    const recovered = agents.send("a", "retry"); await tick(); clients[0].emit("", "error"); clients[0].complete("recovered"); assert.equal((await recovered).status, "done");
  } finally { await agents.closeAll(); }
});

test("timeouts and child crashes fail clearly, stop resources and do not hang", async () => {
  for (const crash of [false, true]) {
    const { agents, clients } = setup({ timeoutMs: 30 });
    await agents.spawn({ id: "a", persona: "A" }, dispatch);
    const task = agents.send("a", "blocked"); await tick();
    if (crash) clients[0].pending!.reject(new Error("Child process exited"));
    const result = await task;
    assert.equal(result.status, "failed"); assert.match(result.error!, crash ? /exited/ : /timed out/);
    assert.equal(agents.list()[0].status, "failed"); assert.equal(clients[0].stopped, 1);
    assert.equal((await agents.send("a", "next")).status, "failed");
    await agents.closeAll();
  }
});

test("close cancels active and queued operations, is idempotent", async () => {
  const { agents, clients } = setup();
  await agents.spawn({ id: "a", persona: "A" }, dispatch);
  const active = agents.send("a", "active"); const queued = agents.send("a", "queued");
  await tick(); await Promise.all([agents.close("a"), agents.close("a"), agents.closeAll()]);
  assert.equal((await active).status, "aborted"); assert.equal((await queued).status, "aborted");
  assert.deepEqual(agents.list(), []); assert.equal(clients[0].listeners.size, 0); assert.equal(clients[0].calls.length, 1);
});

test("startup failure and closeAll during startup clean temp files and reserve IDs", async () => {
  const gate = deferred();
  const { agents, clients, configs } = setup({}, () => { const client = new FakeClient(); client.startGate = gate; return client; });
  const pending = agents.spawn({ id: "a", persona: "A" }, dispatch);
  const failure = assert.rejects(pending, /aborted/);
  while (!clients.length) await tick();
  await assert.rejects(agents.spawn({ id: "a", persona: "A" }, dispatch), /already exists/);
  await agents.closeAll(); await failure;
  gate.resolve(); await tick();
  assert.deepEqual(agents.list(), []); assert.ok(clients[0].stopped >= 1);
  await assert.rejects(access(dirname(configs[0].args![2])));
  const failed = setup({}, () => { const client = new FakeClient(); client.startError = new Error("Startup failed"); return client; });
  await assert.rejects(failed.agents.spawn({ id: "a", persona: "A" }, dispatch), /Startup failed/);
  assert.equal(failed.clients[0].stopped, 1); assert.deepEqual(failed.agents.list(), []);
  await assert.rejects(access(dirname(failed.configs[0].args![2])));
});

test("cancellation during RPC prompt preflight stops the child rather than accepting an idle abort", async () => {
  const controller = new AbortController();
  const agents = new PersistentAgents({ clientFactory: options => {
    const client = new ManagedRpcClient({ ...options, cliPath: fileURLToPath(new URL("./fake-rpc.mjs", import.meta.url)) });
    client.onEvent(event => { if (event.type === "agent_start") controller.abort(); });
    return client;
  } });
  try {
    await agents.spawn({ id: "delayed", persona: "A" }, dispatch);
    const result = await agents.send("delayed", "Never execute after cancellation", controller.signal);
    assert.equal(result.status, "aborted");
    assert.equal(agents.list()[0].status, "failed", "must not reuse a child with an unaccepted prompt");
    assert.equal((await agents.send("delayed", "next")).status, "failed");
  } finally { await agents.closeAll(); }
});

test("registry, identifier, message and trace caps are enforced", async () => {
  const { agents, clients } = setup({ maxAgents: 1 });
  for (const id of ["", "../escape", "a b", "x".repeat(65)]) await assert.rejects(agents.spawn({ id, persona: "A" }, dispatch), /identifier/);
  await assert.rejects(agents.spawn({ persona: "" }, dispatch), /Persona/);
  try {
    await agents.spawn({ id: "a", persona: "A" }, dispatch);
    await assert.rejects(agents.spawn({ id: "b", persona: "B" }, dispatch), /limit/);
    assert.equal((await agents.send("a", "x".repeat(TASK_CAP + 1))).status, "failed"); assert.equal(clients[0].calls.length, 0);
    const updates: string[] = [];
    const task = agents.send("a", "trace", undefined, result => { updates.push(result.output); result.output = "mutated"; });
    await tick(); clients[0].complete("x".repeat(60 * 1024), "stop", 205);
    const result = await task;
    assert.equal(result.trace.length, 200); assert.equal(result.traceOmitted, 5);
    assert.equal((result.trace[0].args.path as string).length, 200); assert.equal(result.trace[0].args.nested, "[…]");
    assert.match(result.output, /Output truncated/); assert.notEqual(result.output, "mutated"); assert.equal(updates.length, 1);
    assert.equal(clients[0].deadline, 600000);
    await assert.rejects(agents.send("missing", "task"), /Unknown/);
  } finally { await agents.closeAll(); }
});
