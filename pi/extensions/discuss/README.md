# Pi discussions

An interactive `/discuss` command that turns the current conversation into an approved brief, then runs two isolated Pi RPC sessions: an author and a reviewer. The coordinator is ordinary code, not another model.

## Start

This directory is auto-discovered through `~/.pi/agent/extensions`. Run `/reload` in an existing Pi session, or start a new Pi session.

Scope the problem normally, then:

```text
/discuss --turns 4 Discuss the migration we scoped. Author: pragmatic engineer, minimize changes. Reviewer: security engineer, challenge assumptions and rollback safety.
```

Your current agent stages a brief from its existing conversation. It cannot use other tools while preparing that brief. No workers run yet.

```text
/discuss approve
```

Review/edit the brief in the multiline editor. Then confirm the personas, models, working directory, and budget. Escape/rejection leaves the draft staged. Workers start in the background, so you can continue using the parent session.

```text
/discuss status
/discuss cancel
/discuss result
```

Completion produces a notification, **not a model message**. `/discuss result` explicitly imports the latest proposal and review without starting a model turn or authorizing implementation. Ask your next question normally.

`status` and `result` accept a discussion ID to inspect another saved discussion. `cancel` only affects this extension's current preparation/draft/run. IDs and files are shown by `status`.

## Options

Put flags before the free-form task/personas:

| Flag | Default | Meaning |
| --- | --- | --- |
| `--turns N` | 4 | Maximum submitted responses, 1–20 |
| `--rounds N` | — | Alternative to turns: N author/reviewer pairs, 1–10 |
| `--timeout N` | 10 | Minutes per worker turn, 1–60 |
| `--author-model provider/id` | Current parent model | Author model |
| `--reviewer-model provider/id` | Current parent model | Reviewer model |

A turn can contain several model calls and read-only tool calls. The timeout bounds each turn, but the turn count is **not a token or dollar budget**. Both workers inherit the parent's thinking level at preparation time. Pi's normal model configuration and authentication are used. Provider extensions are not loaded in workers; use models supported without them.

The default author favors simple solutions and existing conventions. The default reviewer challenges correctness, security, and migration risks. Describe different personas in the request; their generated instructions are displayed before approval. To change personas after staging, cancel and restage.

## Turn protocol

1. Author submits the full proposal, revision 1.
2. Reviewer accepts revision 1 unconditionally, requests changes with stable objection IDs, or requests user input.
3. Author submits the full proposal, revision 2, addressing objections by ID.
4. Reviewer evaluates revision 2.

The author endorses its submitted proposal. Agreement requires the reviewer to accept that exact revision with no unresolved objections. Conditional acceptance must be a change request. Workers cannot change the schedule or extend the budget.

A `submit_discussion_response` tool validates structured responses and terminates the worker's turn. The coordinator waits for both RPC acceptance and `agent_settled`; it does not mistake `agent_end` for final completion.

The coordinator stops on agreement, exhausted budget, a request for user input, cancellation, failure, or timeout. A final author revision at an odd turn limit is explicitly unreviewed. A user-input stop is terminal for this run: answer the question in your main conversation and launch a new discussion with the added context.

## Context and storage

```text
~/.pi/discussions/<uuid>/
  brief.md                 # Approved shared brief; frozen after launch
  config.json              # Personas, models, limits, source session/leaf, cwd
  state.json               # Progress and delivery status
  coordinator.claim        # Exclusive, persistent one-run claim
  deliveries/0001.json     # Assignment; pending → dispatched → completed
  messages/0001.json       # Validated peer response
  sessions/author.jsonl    # Private author context/history
  sessions/reviewer.jsonl  # Private reviewer context/history
  author.stderr.log
  reviewer.stderr.log
  transcript.md            # Explicit peer messages, generated at completion
  result.md                # Latest proposal/review and outcome
```

Directories are created with mode `0700`; files with `0600`. The coordinator is the sole mailbox writer and replaces files through temporary files and atomic rename. Pi itself writes worker session histories. Mailbox files persist until you remove them yourself; they can contain proprietary project details.

The brief contains the task, success criteria, established requirements, existing decisions and rationale, relevant repository paths/context, open questions, and boundaries. Missing facts must be marked unknown, not invented. No raw parent transcript is exported. The brief-preparation exchange remains in the parent context.

Each worker gets the approved brief and its own persona once, then only new peer messages. Its own exploration remains in its private session, not forwarded to the peer or parent. Worker context still grows as the discussion proceeds; the mailbox is not a substitute for a context window.

## Safety and lifecycle

- Workers have only `read`, `grep`, `find`, `ls`, and the submission tool. No shell, edit, or write tools.
- Other extensions, skills, prompt templates, and themes are disabled for workers. Project-local executable configuration is not approved. Repository context instructions are still available through Pi.
- Tool restriction is **not an OS sandbox** or a filesystem access boundary. Read-only tools can access files available to the process. Never put secrets in a brief; use OS isolation if the workspace contains data workers must not access.
- Workers share the **live checkout**, not a frozen repository snapshot. Avoid editing relevant files while they discuss. Only the brief is frozen; later parent messages are not automatically sent to workers.
- Leaving, switching, or reloading the parent session cancels its workers. The extension is not a detached service.
- Graceful cancellation saves a result. An abrupt parent crash may leave a `running` state and a dispatched delivery. Saved messages/sessions remain inspectable. There is no automatic resume/replay or exactly-once guarantee.
- `status` reports when the local extension does not own a run. That run might belong to another Pi process or have been interrupted; it does not guess from PID reuse.
- Drafts cannot be approved after reloading. Restage using the saved brief as context.
- Review agreement is advisory, not evidence that the proposal is correct, tested, or approved for implementation.

## Verification

Node 24 and a Node.js installation of Pi on PATH are required for these tests. No model calls or provider credentials are needed:

```bash
node --test /home/vscode/dotfiles/pi/extensions/discuss/*.test.*
```

Tests cover scheduling, revision validation, early agreement, turn limits, user-input stops, cancellation, duplicate submissions, persistent claims, file permissions, RPC failures/deadlines/framing, extension registration, approval, and explicit result import. RPC discussion tests use fake workers, not paid model requests.
