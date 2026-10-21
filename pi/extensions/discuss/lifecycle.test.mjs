import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import { existsSync, realpathSync } from "node:fs";
import { mkdtemp, readFile, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { test } from "node:test";
import { fileURLToPath, pathToFileURL } from "node:url";

const directory = dirname(fileURLToPath(import.meta.url));
let piPackage = dirname(
  realpathSync(execFileSync("which", ["pi"], { encoding: "utf8" }).trim()),
);
while (!existsSync(join(piPackage, "dist/core/extensions/loader.js"))) {
  const parent = dirname(piPackage);
  if (parent === piPackage)
    throw new Error("Tests require a Node.js Pi installation");
  piPackage = parent;
}
const { loadExtensions } = await import(
  pathToFileURL(join(piPackage, "dist/core/extensions/loader.js")).href
);

test("parent session shutdown cancels an in-flight worker and finalizes its mailbox", async () => {
  const home = await mkdtemp(join(tmpdir(), "pi-discuss-shutdown-"));
  const originalHome = process.env.HOME;
  const originalPath = process.env.PATH;
  process.env.HOME = home;
  process.env.PATH = `${home}:${originalPath}`;
  await writeFile(
    join(home, "pi"),
    `#!${process.execPath}\nprocess.stdin.resume();\n`,
    { mode: 0o700 },
  );
  let shutdown;
  try {
    const loaded = await loadExtensions([join(directory, "index.ts")], home);
    assert.deepEqual(loaded.errors, []);
    const extension = loaded.extensions[0];
    const runtime = loaded.runtime;
    let prompt;
    let tools = [];
    runtime.getActiveTools = () => tools;
    runtime.setActiveTools = next => {
      tools = next;
    };
    runtime.sendUserMessage = message => {
      prompt = message;
    };
    runtime.appendEntry = () => {};
    const ctx = {
      mode: "tui",
      cwd: home,
      model: { provider: "test", id: "model" },
      isIdle: () => true,
      sessionManager: {
        getBranch: () => [],
        getSessionFile: () => undefined,
        getLeafId: () => null,
      },
      ui: {
        notify() {},
        setStatus() {},
        editor: async (_title, brief) => brief,
        confirm: async () => true,
      },
    };
    shutdown = () => extension.handlers.get("session_shutdown")[0]({}, ctx);
    const command = args =>
      extension.commands.get("discuss").handler(args, ctx);
    await command("A lifecycle test");
    const requestId = /requestId=([a-f0-9-]+)/.exec(prompt)[1];
    const room = join(home, ".pi/discussions", requestId);
    await extension.tools
      .get("prepare_discussion")
      .definition.execute(
        "prepare",
        {
          requestId,
          brief: "Test brief",
          authorPersona: "Author",
          reviewerPersona: "Reviewer",
        },
        new AbortController().signal,
        undefined,
        ctx,
      );
    await command("approve");
    const deadline = Date.now() + 5_000;
    while (true) {
      const state = JSON.parse(
        await readFile(join(room, "state.json"), "utf8"),
      );
      if (state.delivery?.status === "dispatched") break;
      assert.ok(Date.now() < deadline, "Worker was not dispatched");
      await new Promise(resolve => setTimeout(resolve, 20));
    }
    await shutdown();
    const final = JSON.parse(await readFile(join(room, "state.json"), "utf8"));
    assert.equal(final.status, "cancelled");
    assert.equal(final.completedTurns, 0);
    assert.match(await readFile(join(room, "result.md"), "utf8"), /cancelled/);
  } finally {
    await shutdown?.();
    if (originalHome === undefined) delete process.env.HOME;
    else process.env.HOME = originalHome;
    if (originalPath === undefined) delete process.env.PATH;
    else process.env.PATH = originalPath;
  }
});
