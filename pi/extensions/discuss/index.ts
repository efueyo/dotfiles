import { randomUUID } from "node:crypto";
import { readFile } from "node:fs/promises";
import { homedir } from "node:os";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";
import {
  atomicWrite,
  coordinate,
  createRoom,
  loadJson,
  parseOptions,
  record,
  saveJson,
  text,
  type Config,
  type State,
} from "./core.ts";
import { RpcWorker, workerArgs } from "./rpc.ts";

const ROOT = join(homedir(), ".pi", "discussions");
const PREPARE = "prepare_discussion";
const HELP = `/discuss [--turns 4 | --rounds 2] [--timeout 10] [--author-model provider/id] [--reviewer-model provider/id] <task and personas>
/discuss approve       Edit the staged brief, review personas, and launch
/discuss status [id]   Show state and storage paths
/discuss cancel        Cancel preparation, draft, or running workers
/discuss result [id]   Import a finished result (no automatic model turn)
/discuss help

Flags precede the task. --timeout is minutes per worker turn. Maximum 20 turns.
Default: author = pragmatic engineer; reviewer = skeptical correctness/security reviewer.
Each turn is one submitted response, not one model/tool call. Workers share the live checkout but have no shell/write/edit tools.
Only the approved brief and explicit peer messages enter worker contexts. Completion only notifies; results are imported explicitly.
Leaving/reloading the parent session cancels workers. Interrupted rooms are inspectable, not automatically resumed.`;

function roomPath(id: string): string {
  if (!/^[a-f0-9-]{36}$/.test(id)) throw new Error("Invalid discussion ID");
  return join(ROOT, id);
}

interface Draft {
  config: Config;
  room: string;
  brief: string;
}
interface Active {
  id: string;
  abort: AbortController;
  done: Promise<void>;
}

export default function discuss(pi: ExtensionAPI): void {
  if (process.env.PI_DISCUSSION_WORKER === "1") return;
  let pending: Config | undefined;
  let draft: Draft | undefined;
  let active: Active | undefined;
  let lastId: string | undefined;
  let staging = false;
  let preparingTurn = false;
  let approving = false;
  let generation = 0;

  function deactivatePreparation(): void {
    pi.setActiveTools(pi.getActiveTools().filter(name => name !== PREPARE));
  }
  async function shutdown(): Promise<void> {
    generation++;
    pending = undefined;
    preparingTurn = false;
    draft = undefined;
    if (active) {
      active.abort.abort();
      await active.done;
      active = undefined;
    }
  }
  pi.on("session_shutdown", shutdown);
  pi.on("tool_call", event => {
    if ((pending || preparingTurn) && event.toolName !== PREPARE)
      return {
        block: true,
        reason:
          "Brief preparation uses existing conversation context only. Submit prepare_discussion or ask the user to cancel preparation.",
      };
  });
  pi.on("agent_settled", () => {
    preparingTurn = false;
  });
  pi.on("session_start", (_event, ctx) => {
    deactivatePreparation();
    lastId = undefined;
    for (const entry of ctx.sessionManager.getBranch()) {
      if (entry.type === "custom" && entry.customType === "discussion-room") {
        try {
          lastId = text(record(entry.data).id, "discussion ID", 36);
        } catch {
          /* Ignore unrelated or malformed session metadata. */
        }
      }
    }
    ctx.ui.setStatus("discuss", undefined);
  });

  pi.registerTool({
    name: PREPARE,
    label: "Prepare discussion brief",
    description:
      "Stage a discussion brief only after the user invokes /discuss. Extract relevant context and proposed personas from the conversation; do not launch workers. Never include secrets or unrelated history. The user must review and approve the brief.",
    parameters: Type.Object({
      requestId: Type.String(),
      brief: Type.String({ minLength: 1, maxLength: 32_000 }),
      authorPersona: Type.String({ minLength: 1, maxLength: 4_000 }),
      reviewerPersona: Type.String({ minLength: 1, maxLength: 4_000 }),
    }),
    async execute(_id, params, signal, _update, ctx) {
      const request = pending;
      if (!request || request.id !== params.requestId || staging)
        throw new Error("No matching /discuss preparation is pending");
      if (ctx.sessionManager.getSessionFile() !== request.sourceSession)
        throw new Error("The originating session changed");
      staging = true;
      try {
        signal?.throwIfAborted();
        const config: Config = {
          ...request,
          authorPersona: text(params.authorPersona, "author persona", 4_000),
          reviewerPersona: text(
            params.reviewerPersona,
            "reviewer persona",
            4_000,
          ),
        };
        const brief = text(params.brief, "brief", 32_000);
        const room = await createRoom(ROOT, config, brief);
        signal?.throwIfAborted();
        if (pending !== request) throw new Error("Preparation cancelled");
        draft = { room, config, brief };
        lastId = config.id;
        pending = undefined;
        deactivatePreparation();
        pi.appendEntry("discussion-room", { id: config.id });
        ctx.ui.notify(
          "Brief staged. Run /discuss approve to edit it and launch workers.",
          "info",
        );
        return {
          content: [
            {
              type: "text",
              text: `Discussion brief staged at ${room}/brief.md. No workers started. Ask the user to run /discuss approve; do not approve on their behalf.`,
            },
          ],
          details: { id: config.id, room },
          terminate: true,
        };
      } finally {
        staging = false;
      }
    },
  });

  pi.registerCommand("discuss", {
    description:
      "Prepare and launch an isolated author/reviewer discussion; /discuss help",
    handler: async (args, ctx) => {
      try {
        if (ctx.mode !== "tui")
          throw new Error("/discuss requires interactive Pi");
        const trimmed = args.trim();
        const [command, id, ...extra] = trimmed.split(/\s+/);
        if (command === "help") {
          ctx.ui.notify(HELP, "info");
          return;
        }
        if (command === "status" || command === "result") {
          if (extra.length) throw new Error(`Usage: /discuss ${command} [id]`);
          const selectedId = id || lastId;
          if (!selectedId) {
            ctx.ui.notify(
              pending
                ? "Preparing brief. /discuss cancel to stop preparation."
                : "No discussion in this session. /discuss help",
              "info",
            );
            return;
          }
          const room = roomPath(selectedId);
          const state = record(await loadJson(join(room, "state.json")));
          if (command === "status") {
            const ownership =
              state.status === "running" && active?.id !== selectedId
                ? "\nThis extension does not own the run. It may belong to another Pi process or have been interrupted. No automatic replay."
                : "";
            ctx.ui.notify(
              `${JSON.stringify(state, null, 2)}${ownership}\nRoom: ${room}\nBrief: ${room}/brief.md\nTranscript: ${room}/transcript.md\nResult: ${room}/result.md`,
              "info",
            );
          } else {
            if (
              state.status === "draft" ||
              state.status === "running" ||
              active?.id === selectedId
            )
              throw new Error("The discussion has no finalized result yet");
            const result = await readFile(join(room, "result.md"), "utf8");
            pi.sendMessage(
              {
                customType: "discussion-result",
                content: `${result}\nFull discussion: ${room}\nThis is an advisory discussion result, not authorization to implement.`,
                display: true,
                details: { id: selectedId },
              },
              { triggerTurn: false, deliverAs: "nextTurn" },
            );
          }
          return;
        }
        if (command === "cancel") {
          if (id) throw new Error("Usage: /discuss cancel");
          pending = undefined;
          preparingTurn = false;
          deactivatePreparation();
          if (draft) {
            await saveJson(join(draft.room, "state.json"), {
              status: "cancelled",
              completedTurns: 0,
            });
            await atomicWrite(
              join(draft.room, "result.md"),
              "# Discussion cancelled\n\nCancelled before worker launch.\n",
            );
            draft = undefined;
          }
          active?.abort.abort();
          ctx.ui.notify(
            "Cancellation requested. Any saved mailbox remains on disk.",
            "info",
          );
          return;
        }
        if (command === "approve") {
          if (id) throw new Error("Usage: /discuss approve");
          if (approving || active)
            throw new Error("A discussion is already launching or running");
          const staged = draft;
          if (!staged)
            throw new Error(
              "No staged brief. Start with /discuss <request>. Drafts from a previous extension runtime must be restaged.",
            );
          approving = true;
          const currentGeneration = generation;
          try {
            const edited = await ctx.ui.editor(
              "Review/edit discussion brief (Escape cancels)",
              staged.brief,
            );
            if (edited === undefined) return;
            const brief = text(edited, "brief", 32_000);
            const config = staged.config;
            const ok = await ctx.ui.confirm(
              "Launch read-only discussion?",
              `${config.turns} turns; ${config.timeoutMinutes} min/turn. Models may incur usage charges.\n\nAuthor (${config.authorModel ?? config.defaultModel}):\n${config.authorPersona}\n\nReviewer (${config.reviewerModel ?? config.defaultModel}):\n${config.reviewerPersona}\n\nWorking directory: ${config.cwd}\nWorkers share the live checkout. They cannot run shell commands or edit files. This is tool restriction, not an OS sandbox.\n\nRoom: ${staged.room}`,
            );
            if (!ok || generation !== currentGeneration || draft !== staged)
              return;
            await atomicWrite(join(staged.room, "brief.md"), brief);
            const abort = new AbortController();
            const extensionPath = join(
              dirname(fileURLToPath(import.meta.url)),
              "worker.ts",
            );
            const update = (state: State) => {
              if (generation === currentGeneration)
                ctx.ui.setStatus(
                  "discuss",
                  `${state.status}: ${state.completedTurns}/${config.turns}${state.activeRole ? ` (${state.activeRole})` : ""}`,
                );
            };
            const done = coordinate(
              staged.room,
              config,
              brief,
              role =>
                new RpcWorker(
                  "pi",
                  workerArgs(staged.room, config, role, extensionPath),
                  config.cwd,
                  join(staged.room, `${role}.stderr.log`),
                  config.timeoutMinutes * 60_000,
                ),
              abort.signal,
              update,
            )
              .then(state => {
                if (generation === currentGeneration)
                  ctx.ui.notify(
                    `Discussion ${state.status}. /discuss result to import; /discuss status for files.`,
                    state.status === "failed" ? "error" : "info",
                  );
              })
              .catch((error: unknown) => {
                if (generation === currentGeneration)
                  ctx.ui.notify(
                    `Discussion coordinator failed: ${error instanceof Error ? error.message : String(error)}. Inspect ${staged.room}; no automatic replay.`,
                    "error",
                  );
              })
              .finally(() => {
                if (active?.id === config.id) active = undefined;
              });
            active = { id: config.id, abort, done };
            draft = undefined;
            ctx.ui.notify(
              `Discussion started: ${config.id}. Continue chatting; /discuss status or /discuss cancel.`,
              "info",
            );
          } finally {
            approving = false;
          }
          return;
        }
        if (pending || draft || active || staging || approving)
          throw new Error(
            "A discussion is already preparing, staged, or running. /discuss approve, status, or cancel.",
          );
        if (!ctx.isIdle())
          throw new Error(
            "Wait until the current response finishes before preparing a discussion",
          );
        if (!ctx.model)
          throw new Error("Select a model before preparing a discussion");
        const options = parseOptions(trimmed);
        const config: Config = {
          ...options,
          id: randomUUID(),
          cwd: ctx.cwd,
          sourceSession: ctx.sessionManager.getSessionFile(),
          sourceLeaf: ctx.sessionManager.getLeafId(),
          defaultModel: `${ctx.model.provider}/${ctx.model.id}`,
          thinking: ctx.thinkingLevel ?? "off",
          authorPersona:
            "Pragmatic senior engineer. Prefer simple changes and existing conventions.",
          reviewerPersona:
            "Skeptical senior engineer. Challenge correctness, security, and migration risks; distinguish blocking concerns from preferences.",
          createdAt: new Date().toISOString(),
        };
        pending = config;
        preparingTurn = true;
        pi.setActiveTools([...new Set([...pi.getActiveTools(), PREPARE])]);
        pi.sendUserMessage(
          `Prepare a brief for an isolated author/reviewer discussion, using our conversation context. Do not solve the task or launch workers. Do not use write/edit/bash or inspect additional files for this preparation; capture relevant paths for workers to inspect.\n\nUser's discussion request/personas:\n${options.request}\n\nCall prepare_discussion exactly once with requestId=${config.id}, brief, authorPersona, reviewerPersona. Use the requested personas or these defaults:\nAuthor: ${config.authorPersona}\nReviewer: ${config.reviewerPersona}\n\nThe brief must be self-contained Markdown with: Task; Success criteria; Established requirements; Existing decisions and rationale (firm constraints vs preferences); Relevant repository context (cwd ${config.cwd}, known revision/dirty changes and relevant paths; mark unknown information unknown); Open questions; Boundaries (discussion only, no implementation, no credentials/secrets). Include only relevant context, never secrets or unrelated history. Do not include the full transcript. The user will edit the brief and approve ${config.turns} turns separately.`,
          { expandPromptTemplates: false },
        );
      } catch (error) {
        ctx.ui.notify(
          error instanceof Error ? error.message : String(error),
          "error",
        );
      }
    },
  });
}
