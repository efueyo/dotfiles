import assert from "node:assert/strict";
import { randomUUID } from "node:crypto";
import { mkdtemp, readFile, readdir, stat } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { test } from "node:test";
import {
  coordinate,
  createRoom,
  loadJson,
  makeAssignment,
  parseOptions,
  parseResponse,
  validateResponse,
  type Assignment,
  type Config,
  type Response,
  type Role,
  type Worker,
} from "./core.ts";

async function setup(turns = 4) {
  const config: Config = {
    ...parseOptions(`--turns ${turns} Decide on a migration`),
    id: randomUUID(),
    cwd: tmpdir(),
    sourceLeaf: null,
    defaultModel: "test/model",
    thinking: "off",
    authorPersona: "Pragmatic",
    reviewerPersona: "Skeptical",
    createdAt: new Date().toISOString(),
  };
  const root = await mkdtemp(join(tmpdir(), "pi-discuss-test-"));
  const brief = "A self-contained test brief";
  return { config, brief, room: await createRoom(root, config, brief) };
}
function response(
  assignment: Assignment,
  decision: Response["decision"],
): Response {
  return {
    turnId: assignment.turnId,
    revision: assignment.revision,
    decision,
    body: `Response for ${assignment.role} revision ${assignment.revision}`,
    objections:
      decision === "request_changes"
        ? [{ id: "R1", text: "Need rollback" }]
        : [],
  };
}

test("parse flags, custom personas, and unambiguous budgets", () => {
  assert.equal(parseOptions("--rounds 4 Security reviewer please").turns, 8);
  assert.equal(parseOptions("").turns, 4);
  assert.equal(
    parseOptions(
      "--turns 3 --timeout 2 --author-model vendor/one --reviewer-model vendor/two Author: pragmatic\nReviewer: skeptical",
    ).reviewerModel,
    "vendor/two",
  );
  for (const args of [
    "--turns 0",
    "--turns 21",
    "--rounds 11",
    "--turns 1.5",
    "--turns 4 --rounds 2",
    "--turns 2 --turns 3",
    "--unknown 2",
    "--timeout 0",
  ])
    assert.throws(() => parseOptions(args));
});

test("responses reject malformed data, wrong revision, role confusion, and conditional acceptance", () => {
  assert.throws(() => parseResponse({}));
  const assignment: Assignment = {
    turnId: "test:2",
    revision: 1,
    role: "reviewer",
    prompt: "Review",
  };
  validateResponse(response(assignment, "accept"), assignment);
  assert.throws(() =>
    validateResponse(
      { ...response(assignment, "accept"), revision: 2 },
      assignment,
    ),
  );
  assert.throws(() =>
    validateResponse(response(assignment, "propose"), assignment),
  );
  assert.throws(() =>
    validateResponse(
      {
        ...response(assignment, "accept"),
        objections: [{ id: "R1", text: "But change this" }],
      },
      assignment,
    ),
  );
  assert.throws(() =>
    validateResponse(
      { ...response(assignment, "request_changes"), objections: [] },
      assignment,
    ),
  );
  assert.throws(() =>
    parseResponse({
      ...response(assignment, "request_changes"),
      objections: [
        { id: "R1", text: "a" },
        { id: "R1", text: "b" },
      ],
    }),
  );
});

test("four turns alternate, only send the brief once per worker, and agree on revision 2", async () => {
  const { room, config, brief } = await setup();
  const assignments: Assignment[] = [];
  const stopped: Role[] = [];
  const decisions: Response["decision"][] = [
    "propose",
    "request_changes",
    "propose",
    "accept",
  ];
  const factory = (role: Role): Worker => ({
    async run(assignment) {
      assignments.push(assignment);
      const delivery = await loadJson(
        join(
          room,
          "deliveries",
          `${String(assignments.length).padStart(4, "0")}.json`,
        ),
      );
      assert.equal(
        typeof delivery === "object" &&
          delivery !== null &&
          "status" in delivery &&
          delivery.status,
        "dispatched",
      );
      const decision = decisions[assignments.length - 1];
      assert.ok(decision);
      return response(assignment, decision);
    },
    async stop() {
      stopped.push(role);
    },
  });
  const state = await coordinate(
    room,
    config,
    brief,
    factory,
    new AbortController().signal,
  );
  assert.equal(state.status, "agreed");
  assert.equal(state.completedTurns, 4);
  assert.deepEqual(
    assignments.map(item => item.role),
    ["author", "reviewer", "author", "reviewer"],
  );
  assert.deepEqual(
    assignments.map(item => item.revision),
    [1, 1, 2, 2],
  );
  assert.ok(assignments[0].prompt.includes(brief));
  assert.ok(assignments[1].prompt.includes(brief));
  assert.ok(!assignments[2].prompt.includes(brief));
  assert.ok(assignments[2].prompt.includes("Need rollback"));
  assert.equal((await readdir(join(room, "messages"))).length, 4);
  assert.deepEqual(stopped.sort(), ["author", "reviewer"]);
  assert.match(await readFile(join(room, "result.md"), "utf8"), /revision 2/);
  assert.equal((await stat(join(room, "brief.md"))).mode & 0o777, 0o600);
  await assert.rejects(
    coordinate(room, config, brief, factory, new AbortController().signal),
    /EEXIST/,
  );
});

test("early acceptance ends at turn 2, without spending the remaining budget", async () => {
  const { room, config, brief } = await setup(8);
  const state = await coordinate(
    room,
    config,
    brief,
    () => ({
      async run(assignment) {
        return response(
          assignment,
          assignment.role === "author" ? "propose" : "accept",
        );
      },
      async stop() {},
    }),
    new AbortController().signal,
  );
  assert.equal(state.status, "agreed");
  assert.equal(state.completedTurns, 2);
});

test("an odd turn limit reports an unreviewed proposal, not agreement", async () => {
  const { room, config, brief } = await setup(3);
  const state = await coordinate(
    room,
    config,
    brief,
    () => ({
      async run(assignment) {
        return response(
          assignment,
          assignment.role === "author" ? "propose" : "request_changes",
        );
      },
      async stop() {},
    }),
    new AbortController().signal,
  );
  assert.equal(state.status, "limit_reached");
  assert.match(
    await readFile(join(room, "result.md"), "utf8"),
    /has not been reviewed/,
  );
});

test("needs_user_input pauses the workflow without pretending consensus", async () => {
  const { room, config, brief } = await setup();
  const state = await coordinate(
    room,
    config,
    brief,
    () => ({
      async run(assignment) {
        return response(assignment, "needs_user_input");
      },
      async stop() {},
    }),
    new AbortController().signal,
  );
  assert.equal(state.status, "needs_user_input");
  assert.equal(state.completedTurns, 1);
});

test("cancel and failure both preserve delivery state and stop workers", async () => {
  for (const cancel of [false, true]) {
    const { room, config, brief } = await setup();
    const abort = new AbortController();
    let stopped = false;
    const state = await coordinate(
      room,
      config,
      brief,
      () => ({
        async run() {
          if (cancel) abort.abort();
          throw new Error("Interrupted");
        },
        async stop() {
          stopped = true;
        },
      }),
      abort.signal,
    );
    assert.equal(state.status, cancel ? "cancelled" : "failed");
    assert.equal(state.delivery?.status, "dispatched");
    assert.equal(state.completedTurns, 0);
    assert.equal(stopped, true);
    assert.equal((await readdir(join(room, "messages"))).length, 0);
  }
});

test("first assignment uses role-specific persona", async () => {
  const { config, brief } = await setup();
  const first = makeAssignment(config, brief, []);
  assert.match(first.prompt, /Pragmatic/);
  assert.ok(!first.prompt.includes("Skeptical"));
});
