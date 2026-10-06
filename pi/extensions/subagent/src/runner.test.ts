import assert from "node:assert/strict";
import { test } from "node:test";
import { existsSync } from "node:fs";
import { tmpdir } from "node:os";
import { fileURLToPath } from "node:url";
import { mapWithConcurrency, runTask, TASK_CAP, type Dispatch } from "./runner.js";

const fixture = fileURLToPath(new URL("./fake-pi.mjs", import.meta.url));
const dispatch: Dispatch = {
  cwd: tmpdir(), model: "parent/model", thinkingLevel: "high",
  invocation: (args) => ({ command: process.execPath, args: [fixture, ...args] }),
};
const report = (output: string) => JSON.parse(output) as { args: string[]; env: string | null; cwd: string };

test("read-only task inherits the parent model, restricts tools and returns only the final report", async () => {
  const updates: number[] = [];
  const result = await runTask({ description: "Explore", task: "@look around" }, dispatch, undefined, (partial) => updates.push(partial.usage.turns));
  assert.equal(result.status, "done", result.error);
  const { args, env, cwd } = report(result.output);
  assert.deepEqual(args.slice(0, 4), ["--mode", "json", "-p", "--no-session"]);
  assert.deepEqual(args.slice(args.indexOf("--model"), args.indexOf("--model") + 2), ["--model", "parent/model"]);
  assert.deepEqual(args.slice(args.indexOf("--thinking"), args.indexOf("--thinking") + 2), ["--thinking", "high"]);
  assert.deepEqual(args.slice(args.indexOf("--tools"), args.indexOf("--tools") + 2), ["--tools", "read,grep,find,ls,bash"]);
  assert.equal(args.at(-2), "--");
  assert.equal(args.at(-1), "Task:\n@look around", "a leading @ must not be read as a file input");
  const promptPath = args[args.indexOf("--append-system-prompt") + 1];
  assert.equal(existsSync(promptPath), false, "temporary system prompt is removed");
  assert.equal(env, "1", "children are marked so they never register the tool");
  assert.equal(cwd, tmpdir());
  assert.deepEqual(updates, [1, 2]);
  assert.equal(result.usage.turns, 2);
  assert.equal(result.usage.input, 20);
  assert.equal(result.usage.cost, 0.02);
  assert.equal(result.usage.contextTokens, 16);
  assert.equal(result.model, "fake/model");
  assert.equal(result.trace.length, 1);
  assert.equal(result.trace[0].tool, "read");
  assert.ok(String(result.trace[0].args.content).length < 250, "trace arguments are shortened");
  assert.ok(!JSON.stringify(result).includes("huge tool output"), "child tool outputs are not kept");
});

test("full access excludes only the subagent tool; an explicit model drops the inherited thinking level", async () => {
  const result = await runTask({ description: "Edit", task: "change it", access: "full", model: "other/model", cwd: "/" }, dispatch, undefined);
  const { args, cwd } = report(result.output);
  assert.deepEqual(args.slice(args.indexOf("--exclude-tools"), args.indexOf("--exclude-tools") + 2), ["--exclude-tools", "subagent"]);
  assert.equal(args.includes("--tools"), false);
  assert.equal(args.includes("--thinking"), false);
  assert.equal(args[args.indexOf("--model") + 1], "other/model");
  assert.equal(cwd, "/");
});

test("failures report stderr or the model error; oversized tasks never start", async () => {
  const crashed = await runTask({ description: "Crash", task: "[exit-nonzero]" }, dispatch, undefined);
  assert.equal(crashed.status, "failed");
  assert.equal(crashed.error, "fake pi crashed");
  const errored = await runTask({ description: "Error", task: "[model-error]" }, dispatch, undefined);
  assert.equal(errored.status, "failed");
  assert.equal(errored.error, "rate limited");
  let started = false;
  const oversized = await runTask({ description: "Big", task: "x".repeat(TASK_CAP + 1) },
    { ...dispatch, invocation: (args) => { started = true; return dispatch.invocation!(args); } }, undefined);
  assert.equal(oversized.status, "failed");
  assert.match(oversized.error ?? "", /Write the context to a file/);
  assert.equal(started, false);
  const missing = await runTask({ description: "Missing", task: "x" }, { ...dispatch, invocation: () => ({ command: "/nonexistent/pi", args: [] }) }, undefined);
  assert.equal(missing.status, "failed");
});

test("aborting kills the child promptly", async () => {
  const controller = new AbortController();
  const started = Date.now();
  const running = runTask({ description: "Hang", task: "[hang]" }, dispatch, controller.signal, (partial) => {
    if (partial.output === "starting") controller.abort();
  });
  const result = await running;
  assert.equal(result.status, "aborted");
  assert.ok(Date.now() - started < 4000);
});

test("parallel tasks respect the concurrency limit", async () => {
  let active = 0;
  let peak = 0;
  const results = await mapWithConcurrency([1, 2, 3, 4, 5], 2, async (value) => {
    active++; peak = Math.max(peak, active);
    await new Promise((resolve) => setTimeout(resolve, 20));
    active--;
    return value * 2;
  });
  assert.deepEqual(results, [2, 4, 6, 8, 10]);
  assert.equal(peak, 2);
});
