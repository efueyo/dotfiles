import assert from "node:assert/strict";
import { test } from "node:test";
import { mkdtemp, mkdir, rm, symlink } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";
import { discoverAndLoadExtensions, type ExtensionContext } from "@earendil-works/pi-coding-agent";

async function load(t: { after: (fn: () => Promise<void>) => void }) {
  const directory = await mkdtemp(join(tmpdir(), "subagent-discovery-test-"));
  t.after(() => rm(directory, { recursive: true, force: true }));
  const agent = join(directory, "agent");
  await mkdir(join(agent, "extensions"), { recursive: true });
  await symlink(fileURLToPath(new URL("../", import.meta.url)), join(agent, "extensions", "subagent"));
  return discoverAndLoadExtensions([], directory, agent);
}

test("pi loads only src/index.ts, which registers both subagent tools", async (t) => {
  const result = await load(t);
  assert.deepEqual(result.errors, []);
  assert.equal(result.extensions.length, 1);
  assert.ok(result.extensions[0].path.endsWith("src/index.ts"));
  assert.deepEqual([...result.extensions[0].tools.keys()], ["subagent_session", "subagent"]);
});

test("children do not register the tool", async (t) => {
  process.env.PI_SUBAGENT = "1";
  try {
    const result = await load(t);
    assert.equal(result.extensions[0].tools.size, 0);
  } finally {
    delete process.env.PI_SUBAGENT;
  }
});

test("parallel execution returns each report and flags a batch where every task failed", async (t) => {
  const result = await load(t);
  const extension = result.extensions[0];
  const tool = extension.tools.get("subagent")!.definition;
  const onResult = extension.handlers.get("tool_result")![0];
  const script = process.argv[1];
  // The tool starts children like pi re-running itself: process.execPath + process.argv[1].
  process.argv[1] = fileURLToPath(new URL("./fake-pi.mjs", import.meta.url));
  t.after(() => { process.argv[1] = script; });
  const ctx = { cwd: tmpdir(), model: { provider: "parent", id: "model" }, thinkingLevel: "medium" } as unknown as ExtensionContext;
  const updates: string[] = [];

  const batch = await tool.execute("call", {
    tasks: [
      { description: "First", task: "[slow] one" },
      { description: "Second", task: "[slow] two" },
      { description: "Broken", task: "[exit-nonzero]" },
    ],
  }, undefined, (update) => { const first = update.content[0]; if (first?.type === "text") updates.push(first.text); }, ctx);
  const text = (batch.content[0] as { text: string }).text;
  assert.match(text, /^2\/3 subagents succeeded/);
  assert.match(text, /### \[First\] done/);
  assert.match(text, /### \[Broken\] failed\n\nfake pi crashed/);
  assert.ok(updates.includes("3/3 done"));
  assert.equal(await onResult({ type: "tool_result", toolName: "subagent", details: batch.details }, ctx), undefined, "partial failure is not an error");

  const single = await tool.execute("call", { description: "Broken", task: "[exit-nonzero]" }, undefined, undefined, ctx);
  assert.deepEqual(await onResult({ type: "tool_result", toolName: "subagent", details: single.details }, ctx), { isError: true });
  await assert.rejects(tool.execute("call", {}, undefined, undefined, ctx), /Provide either/);
});

test("persistent tool spawns real RPC children, reads history and cleans up on shutdown without model calls", async (t) => {
  const result = await load(t);
  const extension = result.extensions[0];
  const tool = extension.tools.get("subagent_session")!.definition;
  const shutdown = extension.handlers.get("session_shutdown")![0];
  const ctx = { cwd: tmpdir() } as unknown as ExtensionContext;
  t.after(async () => { await shutdown({ type: "session_shutdown" }, ctx); });
  const execute = (params: Parameters<typeof tool.execute>[1]) => tool.execute("call", params, undefined, undefined, ctx);
  await assert.rejects(execute({ action: "spawn" }), /requires persona/);
  await assert.rejects(execute({ action: "send", message: "hi" }), /requires agentId/);
  await execute({ action: "spawn", agentId: "writer", persona: "Write pun jokes and remember prior feedback." });
  await assert.rejects(execute({ action: "spawn", agentId: "writer", persona: "Duplicate" }), /already exists/);
  const listed = await execute({ action: "list" });
  assert.match((listed.content[0] as { text: string }).text, /"id": "writer"/);
  const history = await execute({ action: "history", agentId: "writer" });
  assert.match((history.content[0] as { text: string }).text, /"total": 0/);
  await assert.rejects(execute({ action: "send", agentId: "writer" }), /requires a nonempty message/);
  await execute({ action: "close", agentId: "writer" });
  await execute({ action: "spawn", agentId: "editor", persona: "Edit jokes." });
  await shutdown({ type: "session_shutdown" }, ctx);
  assert.equal((await execute({ action: "list" })).content[0].type, "text");
  assert.equal(((await execute({ action: "list" })).content[0] as { text: string }).text, "[]");
});
