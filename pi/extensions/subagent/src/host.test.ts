import assert from "node:assert/strict";
import { mkdtemp, mkdir, rm, symlink, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";
import test from "node:test";

// Optional integration against the installed host SDK, which may differ from
// this extension's pinned devDependency. No credentials/model calls needed.
const hostPackage = process.env.PI_TEST_HOST_PACKAGE;
test("host SDK and child CLI stay aligned when extension devDependencies differ", { skip: !hostPackage }, async t => {
  const host = await import(pathToFileURL(join(hostPackage!, "dist/index.js")).href);
  const directory = await mkdtemp(join(tmpdir(), "subagent-host-test-"));
  t.after(() => rm(directory, { recursive: true, force: true }));
  const agentDir = join(directory, "agent");
  await mkdir(join(agentDir, "extensions"), { recursive: true });
  await symlink(fileURLToPath(new URL("../", import.meta.url)), join(agentDir, "extensions", "subagent"));
  // Consume child prompts without contacting a provider. New RPC returns
  // disposition=handled; the old CLI instead returned no response data.
  await writeFile(join(agentDir, "extensions", "consume.ts"), `export default function(pi) {
    pi.on("input", () => ({ action: "handled" }));
  }`);
  const previous = process.env.PI_CODING_AGENT_DIR;
  process.env.PI_CODING_AGENT_DIR = agentDir;
  t.after(() => {
    if (previous === undefined) delete process.env.PI_CODING_AGENT_DIR;
    else process.env.PI_CODING_AGENT_DIR = previous;
  });
  const loaded = await host.discoverAndLoadExtensions([], directory, agentDir);
  assert.deepEqual(loaded.errors, []);
  const extension = loaded.extensions.find((entry: { tools: Map<string, unknown> }) => entry.tools.has("subagent_session"));
  assert.ok(extension);
  const tool = extension.tools.get("subagent_session").definition;
  const context = { cwd: directory };
  const shutdown = extension.handlers.get("session_shutdown")[0];
  t.after(() => shutdown({ type: "session_shutdown" }, context));
  const execute = (params: Record<string, unknown>) => tool.execute("test", params, undefined, undefined, context);
  await execute({ action: "spawn", agentId: "jokester", persona: "Write puns." });
  for (const message of ["Write five jokes.", "Improve the jokes."]) {
    const result = await execute({ action: "send", agentId: "jokester", message });
    assert.equal(result.isError, false);
    assert.equal(result.details.results[0].status, "done");
  }
  const history = await execute({ action: "history", agentId: "jokester" });
  assert.equal(history.details.data.total, 0);
  const listed = await execute({ action: "list" });
  assert.equal(listed.details.data[0].status, "idle");
});
