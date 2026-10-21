import assert from "node:assert/strict";
import { mkdtemp } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { test } from "node:test";
import type { Assignment } from "./core.ts";
import { RpcWorker, workerArgs } from "./rpc.ts";

const fakePi = String.raw`
const mode = process.argv[1];
const send = (record) => process.stdout.write(JSON.stringify(record) + '\n');
let buffer = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', (chunk) => {
  buffer += chunk;
  let n;
  while ((n = buffer.indexOf('\n')) >= 0) {
    const command = JSON.parse(buffer.slice(0, n)); buffer = buffer.slice(n + 1);
    if (mode === 'exit') { process.exit(7); return; }
    if (mode === 'reject') { send({type:'response', id:command.id, success:false, error:'Rejected'}); return; }
    if (mode === 'hang') return;
    if (mode === 'malformed') { process.stdout.write('not-json\n'); return; }
    const response = {type:'response', id:command.id, success:true};
    if (mode !== 'late-ack') send(response);
    if (mode === 'no-submission') { send({type:'agent_settled'}); return; }
    const submission = {type:'tool_execution_end', toolName:'submit_discussion_response', isError:false,
      result:{details:{turnId:command.id, revision:1, decision:'propose', body:'Unicode\u2028separator\u2029retained', objections:[]}}};
    send(submission);
    if (mode === 'duplicate') send(submission);
    send({type:'agent_end'});
    setTimeout(() => { send({type:'agent_settled'}); if (mode === 'late-ack') send(response); }, 30);
  }
});
`;
const assignment: Assignment = {
  turnId: "test:1",
  revision: 1,
  role: "author",
  prompt: "Task",
};
async function worker(mode: string, timeout = 1_000) {
  const dir = await mkdtemp(join(tmpdir(), "pi-discuss-rpc-"));
  return new RpcWorker(
    process.execPath,
    ["-e", fakePi, mode],
    dir,
    join(dir, "stderr.log"),
    timeout,
  );
}

test("RPC waits for settlement, handles late prompt ack and preserves Unicode separators", async () => {
  for (const mode of ["normal", "late-ack"]) {
    const rpc = await worker(mode);
    try {
      const result = await rpc.run(assignment, new AbortController().signal);
      assert.equal(result.body, "Unicode\u2028separator\u2029retained");
      const again = await rpc.run(
        { ...assignment, turnId: "test:3" },
        new AbortController().signal,
      );
      assert.equal(again.turnId, "test:3");
    } finally {
      await rpc.stop();
    }
  }
});

test("RPC detects rejection, exit, missing/duplicate submissions, and malformed output", async () => {
  for (const mode of [
    "reject",
    "exit",
    "no-submission",
    "duplicate",
    "malformed",
  ]) {
    const rpc = await worker(mode);
    try {
      await assert.rejects(rpc.run(assignment, new AbortController().signal));
    } finally {
      await rpc.stop();
    }
  }
});

test("RPC deadline and cancellation stop a hanging worker", async () => {
  const timed = await worker("hang", 50);
  try {
    await assert.rejects(
      timed.run(assignment, new AbortController().signal),
      /exceeded/,
    );
  } finally {
    await timed.stop();
  }
  const cancelled = await worker("hang");
  const abort = new AbortController();
  const promise = cancelled.run(assignment, abort.signal);
  abort.abort();
  try {
    await assert.rejects(promise, /cancelled/);
  } finally {
    await cancelled.stop();
    await cancelled.stop();
  }
});

test("RPC reports executable startup failure", async () => {
  const dir = await mkdtemp(join(tmpdir(), "pi-discuss-rpc-"));
  const rpc = new RpcWorker(
    join(dir, "does-not-exist"),
    [],
    dir,
    join(dir, "stderr.log"),
    1_000,
  );
  try {
    await assert.rejects(
      rpc.run(assignment, new AbortController().signal),
      /Could not start Pi/,
    );
  } finally {
    await rpc.stop();
  }
});

test("worker invocation isolates extensions and restricts tools", () => {
  const args = workerArgs(
    "/room",
    {
      id: "test",
      cwd: "/repo",
      sourceLeaf: null,
      createdAt: "now",
      defaultModel: "default/model",
      thinking: "off",
      turns: 4,
      timeoutMinutes: 10,
      request: "task",
      authorPersona: "a",
      reviewerPersona: "r",
      reviewerModel: "other/model",
    },
    "reviewer",
    "/worker.ts",
  );
  assert.ok(args.includes("--no-extensions"));
  assert.ok(args.includes("--no-approve"));
  assert.equal(
    args[args.indexOf("--tools") + 1],
    "read,grep,find,ls,submit_discussion_response",
  );
  assert.equal(args[args.indexOf("--model") + 1], "other/model");
  assert.equal(
    args[args.indexOf("--session") + 1],
    "/room/sessions/reviewer.jsonl",
  );
});
