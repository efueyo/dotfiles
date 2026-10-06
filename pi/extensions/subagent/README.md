# Subagent for pi

A generic `subagent` tool: the model hands a self-contained task to a separate
`pi` process with a fresh context window, and gets back only its final report.
Use it to keep exploration out of the main context, or to keep independent work
(for example, writing a plan and reviewing it) from influencing each other.
There are no predefined roles; the task text is the whole brief.

For multi-turn collaboration, `subagent_session` creates named agents backed by
long-lived `pi --mode rpc` processes. Each retains its own conversation; the
parent chooses which messages to forward between agents.

pi loads only `src/index.ts` (via the package manifest). There are no runtime
dependencies; `pi/extensions` is already linked by `install.sh`/`make install`.
Use `/reload` in a running session.

## Parameters

Single task:

```json
{ "description": "Verify build commands", "task": "…", "access": "read-only" }
```

Parallel (max 8, 4 at a time):

```json
{ "tasks": [{ "description": "…", "task": "…" }, { "description": "…", "task": "…", "access": "full" }] }
```

- `task`: everything the subagent needs. It cannot see the parent conversation.
  Tasks over 100 KiB are rejected; write long context to a file and reference it.
- `access`: `read-only` (default) runs with `--tools read,grep,find,ls,bash`;
  `full` keeps every tool except `subagent`.
- `model`: `provider/model`. By default the child uses the parent's current model
  and thinking level.
- `cwd`: working directory, relative to the parent's.

## Persistent agents: `subagent_session`

```json
{ "action": "spawn", "agentId": "writer", "persona": "Write short pun jokes. Remember and apply the editor's feedback." }
{ "action": "spawn", "agentId": "editor", "persona": "Critique pun jokes and suggest specific improvements." }
{ "action": "send", "agentId": "writer", "message": "Write five jokes." }
{ "action": "send", "agentId": "editor", "message": "Review these jokes: <writer's reply>" }
{ "action": "send", "agentId": "writer", "message": "Revise using this feedback: <editor's reply>" }
{ "action": "list" }
{ "action": "history", "agentId": "writer", "offset": 0, "limit": 20 }
{ "action": "close", "agentId": "writer" }
{ "action": "close", "agentId": "editor" }
```

Repeat the editor/writer sends for as many improvement rounds as needed. The
placeholders above are replaced with actual replies by the parent, not routed
automatically. Agents cannot see the parent's or each other's conversation.

- `spawn` requires `persona`; `agentId` is optional (generated if omitted).
  IDs must be 1–64 letters, digits, underscores or hyphens, starting with a letter
  or digit. Duplicate IDs are rejected. At most eight agents can be open.
- `access`, `model` and `cwd` are optional at spawn, with the same defaults as
  one-shot tasks. Persona and configuration stay fixed for the agent's lifetime.
- `send` requires `agentId` and a nonempty `message`. It waits for the completed
  run and returns only that send's final reply, plus usage/tool traces in details.
  Messages are capped at 100 KiB; model-facing replies at 50 KiB.
- Sends and history reads are FIFO for each agent. Different agents can work in
  parallel. An active send has a ten-minute deadline.
- `history` reads the current conversation context (which may be compacted),
  with a message offset and page size (default 20, maximum 100). It includes
  `total`. Model-facing output is capped at 50 KiB; reduce page size if truncated.
- Cancellation aborts the active send; queued canceled messages are not sent.
  Cancellation before prompt acceptance stops the child to prevent a delayed
  canceled task from starting; close it and spawn a replacement in that case.
  Timeout or transport failure stops the child and marks it failed: close it and
  spawn a replacement. Model errors are reported without returning old replies.
- `close` stops an agent and releases its ID; closing an unknown ID is harmless.
  Parent session shutdown, session replacement or extension reload closes all
  children. Agents are started lazily, not during extension discovery.
- **Memory is session-scoped, not durable.** Children use `--no-session`, retaining
  history in memory until closed. Restarting/resuming the parent does not restore
  agents; saved tool results are not live child sessions. Ordinary Pi context
  limits and automatic compaction still apply.

## One-shot behavior

- Each task runs `pi --mode json -p --no-session` with a short appended system
  prompt: no conversation access, no user to ask, finish with a concise report.
- Only the final assistant message is returned (capped at 50 KiB per task). A
  parallel batch is reported as an error only if every task failed.
- The UI shows live tool calls, token usage and cost; Ctrl+O expands the task
  and full report. Tool result details keep a compact trace, not the child's
  tool outputs, since pi saves details in the parent session.
- Ctrl+C / abort sends SIGTERM to children (SIGKILL after 5 seconds).
- Subagents cannot start subagents: orchestration tools are not registered in children,
  and children (marked with `PI_SUBAGENT=1`) do not register it.

## Safety

Children load your other extensions and skills but have no UI. `safety.ts` and
MCP `confirm` policies therefore block anything that would normally ask for
confirmation. Children inherit the environment, including
`PI_DANGEROUSLY_SKIP_PERMISSIONS`, so a session with that set grants the same to
its subagents.

`read-only` removes the edit and write tools, but `bash` can still modify files;
only the system prompt tells the child not to. Treat it as "no editing tools",
not a sandbox.

## Development

```sh
cd pi/extensions/subagent
npm ci --ignore-scripts
npm run check
npm test
# Optional: test against an installed host Pi that differs from devDependencies.
PI_TEST_HOST_PACKAGE=/absolute/path/to/@earendil-works/pi-coding-agent npm test
```

Tests use fake clients/CLI fixtures plus real RPC lifecycle checks, without model
or network calls. The optional host test exercises spawn, repeated sends and
history through the installed host's extension loader, ensuring the RPC client
and child CLI come from the same Pi package even when devDependencies differ.
