import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import { existsSync, realpathSync } from "node:fs";
import { mkdtemp, readFile, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { after, test } from "node:test";
import { fileURLToPath, pathToFileURL } from "node:url";

const directory = dirname(fileURLToPath(import.meta.url));
let piPackage = dirname(
  realpathSync(execFileSync("which", ["pi"], { encoding: "utf8" }).trim()),
);
while (!existsSync(join(piPackage, "dist/core/extensions/loader.js"))) {
  const parent = dirname(piPackage);
  if (parent === piPackage)
    throw new Error(
      "Tests require a Node.js Pi installation with the extension loader",
    );
  piPackage = parent;
}
const { loadExtensions } = await import(
  pathToFileURL(join(piPackage, "dist/core/extensions/loader.js")).href
);
const home = await mkdtemp(join(tmpdir(), "pi-discuss-ui-"));
const originalHome = process.env.HOME;
process.env.HOME = home;
after(() => {
  if (originalHome === undefined) delete process.env.HOME;
  else process.env.HOME = originalHome;
});

async function harness() {
  const loaded = await loadExtensions([join(directory, "index.ts")], home);
  assert.deepEqual(loaded.errors, []);
  const extension = loaded.extensions[0];
  const prompts = [];
  const imported = [];
  const entries = [];
  const notifications = [];
  let tools = ["read", "write", "prepare_discussion"];
  loaded.runtime.getActiveTools = () => tools;
  loaded.runtime.setActiveTools = next => {
    tools = next;
  };
  loaded.runtime.sendUserMessage = message => prompts.push(message);
  loaded.runtime.sendMessage = (message, options) =>
    imported.push({ message, options });
  loaded.runtime.appendEntry = (customType, data) =>
    entries.push({ type: "custom", customType, data });
  const ctx = {
    mode: "tui",
    cwd: home,
    thinkingLevel: "off",
    model: { provider: "test", id: "model" },
    isIdle: () => true,
    sessionManager: {
      getBranch: () => entries,
      getSessionFile: () => join(home, "parent.jsonl"),
      getLeafId: () => "leaf",
    },
    ui: {
      notify: message => notifications.push(message),
      setStatus() {},
      editor: async (_title, brief) => brief,
      confirm: async () => false,
    },
  };
  const emit = async (name, event = {}) => {
    for (const handler of extension.handlers.get(name) ?? [])
      await handler(event, ctx);
  };
  await emit("session_start");
  const command = args => extension.commands.get("discuss").handler(args, ctx);
  const prepare = async () => {
    const requestId = /requestId=([a-f0-9-]+)/.exec(prompts.at(-1))?.[1];
    assert.ok(requestId);
    await extension.tools.get("prepare_discussion").definition.execute(
      "tool-1",
      {
        requestId,
        brief: "# Task\nTest the agreed approach. No implementation.",
        authorPersona: "Pragmatic author",
        reviewerPersona: "Security reviewer",
      },
      new AbortController().signal,
      undefined,
      ctx,
    );
    return { requestId, room: join(home, ".pi", "discussions", requestId) };
  };
  return {
    extension,
    command,
    prepare,
    emit,
    ctx,
    prompts,
    imported,
    entries,
    notifications,
    getTools: () => tools,
  };
}

test("brief staging requires user invocation, disables unrelated tools, and awaits approval", async () => {
  const h = await harness();
  assert.ok(!h.getTools().includes("prepare_discussion"));
  await assert.rejects(
    h.extension.tools
      .get("prepare_discussion")
      .definition.execute(
        "x",
        { requestId: "wrong" },
        undefined,
        undefined,
        h.ctx,
      ),
    /No matching/,
  );
  await h.command(
    "--turns 4 Author: pragmatic. Reviewer: security specialist.",
  );
  assert.equal(h.prompts.length, 1);
  assert.ok(h.getTools().includes("prepare_discussion"));
  const blocks = await Promise.all(
    h.extension.handlers
      .get("tool_call")
      .map(handler => handler({ toolName: "write" }, h.ctx)),
  );
  assert.ok(blocks.some(result => result?.block));
  const { room } = await h.prepare();
  assert.ok(!h.getTools().includes("prepare_discussion"));
  assert.equal(
    JSON.parse(await readFile(join(room, "state.json"), "utf8")).status,
    "draft",
  );
  await h.command("approve");
  assert.equal(
    JSON.parse(await readFile(join(room, "state.json"), "utf8")).status,
    "draft",
  );
  assert.equal(h.imported.length, 0);
  await h.command("cancel");
  await h.command("result");
  assert.equal(h.imported.length, 1);
  assert.equal(h.imported[0].options.triggerTurn, false);
  await h.emit("session_shutdown");
});

test("approved command runs isolated RPC workers; completion stays outside parent context until result", async () => {
  const h = await harness();
  const bin = await mkdtemp(join(tmpdir(), "pi-discuss-bin-"));
  const fakePi = `#!${process.execPath}
const role = process.argv[process.argv.indexOf('--name') + 1].split(':').at(-1);
let buffer = '';
const send = record => process.stdout.write(JSON.stringify(record) + '\\n');
process.stdin.setEncoding('utf8');
process.stdin.on('data', chunk => {
  buffer += chunk;
  let newline;
  while ((newline = buffer.indexOf('\\n')) >= 0) {
    const command = JSON.parse(buffer.slice(0,newline)); buffer = buffer.slice(newline+1);
    send({type:'response',id:command.id,success:true});
    const revision = Number(/revision=(\\d+)/.exec(command.message)[1]);
    send({type:'tool_execution_end',toolName:'submit_discussion_response',isError:false,result:{details:{turnId:command.id,revision,decision:role === 'author' ? 'propose' : 'accept',body:role === 'author' ? 'Use the simplest solution.' : 'Unconditionally accepted.',objections:[]}}});
    send({type:'agent_settled'});
  }
});
`;
  await writeFile(join(bin, "pi"), fakePi, { mode: 0o700 });
  const originalPath = process.env.PATH;
  process.env.PATH = `${bin}:${originalPath}`;
  try {
    await h.command("--turns 4 Review the current plan");
    const { room } = await h.prepare();
    h.ctx.ui.editor = async (_title, brief) =>
      `${brief}\nUser-added requirement.`;
    h.ctx.ui.confirm = async () => true;
    await h.command("approve");
    const deadline = Date.now() + 5_000;
    while (
      !h.notifications.some(message => message.includes("Discussion agreed."))
    ) {
      if (Date.now() > deadline) assert.fail(h.notifications.join("\n"));
      await new Promise(resolve => setTimeout(resolve, 20));
    }
    assert.match(
      await readFile(join(room, "brief.md"), "utf8"),
      /User-added requirement/,
    );
    assert.equal(
      JSON.parse(await readFile(join(room, "state.json"), "utf8"))
        .completedTurns,
      2,
    );
    assert.equal(h.imported.length, 0);
    assert.equal(h.prompts.length, 1);
    await h.command("result");
    assert.equal(h.imported.length, 1);
    assert.match(h.imported[0].message.content, /Use the simplest solution/);
  } finally {
    await h.emit("session_shutdown");
    if (originalPath === undefined) delete process.env.PATH;
    else process.env.PATH = originalPath;
  }
});

test("worker submission terminates, rejects duplicates, and blocks mutation tools", async () => {
  const loaded = await loadExtensions([join(directory, "worker.ts")], home);
  assert.deepEqual(loaded.errors, []);
  const extension = loaded.extensions[0];
  const tool = extension.tools.get("submit_discussion_response").definition;
  const params = {
    turnId: "test:1",
    revision: 1,
    decision: "propose",
    body: "Proposal",
    objections: [],
  };
  const result = await tool.execute("one", params);
  assert.equal(result.terminate, true);
  await assert.rejects(tool.execute("two", params), /Already submitted/);
  const guard = extension.handlers.get("tool_call")[0];
  assert.equal(guard({ toolName: "bash" }).block, true);
  assert.equal(guard({ toolName: "edit" }).block, true);
  assert.equal(guard({ toolName: "read" }), undefined);
});
