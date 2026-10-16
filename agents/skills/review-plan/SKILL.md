---
name: review-plan
description: Review a feature implementation plan (context.md, prompt.md, tasks.json) for completeness and quality
---

# Review Implementation Plan

Analyze the feature plan named in the user's request for completeness and quality. Companion skill to
`create-plan` — same generic, any-repo approach, no fixed language or architecture assumed.

## Discover Project Architecture First

Don't assume a language, layer split, or toolchain — this skill runs in many different repos.
Before reviewing anything:

- Read `CLAUDE.md`, `AGENTS.md`, and `README.md` at the repo root (and in relevant
  subdirectories) for documented architecture, layers, and build/test/lint commands.
- If those are missing or incomplete, explore: `package.json`/`go.mod`/`Cargo.toml`/
  `pyproject.toml`, `Makefile`/`justfile`/`turbo.jsonc`/`Taskfile.yml`, and the directory
  structure (`apps/`, `packages/`, `server/`, `web/`, `src/`, `cmd/`, `internal/`, `shared/`,
  `proto/`, etc.) to infer the layers/workspaces.
- If the repo is a monorepo with independent layers, note each layer's language, location,
  build command, test command, and lint/format command — you'll check the plan's commands
  against these.
- You'll use this to judge whether the plan's file paths, build/test commands, and task
  ordering actually match the repo, not just whether they're internally consistent.

## Instructions

1. **Read the plan files**:
   - `mytasks/active/{feature-name}/context.md` — feature specification
   - `mytasks/active/{feature-name}/prompt.md` — agent instructions
   - `mytasks/active/{feature-name}/tasks.json` — task list

2. **Review the current code state and independently challenge the design** — verify paths and
   integration points against the discovered architecture, then apply the Design Challenge below
   before evaluating task completeness. Do not limit exploration to files named in the plan.

3. **Check approval requirements and unattended readiness** using the process below. Resolve
   approval gates before declaring the plan ready for unattended execution.

4. **Present an overview covering**:

### Approval Gates and Unattended Readiness

- Read the repository's autonomy and approval rules. Identify every task that requires human
  approval and cite the applicable rule; do not invent approval gates where none are required.
- Explain the exact restricted change, its purpose, and its scope in plain language. Separate
  implementation/local verification from production deployment, data inspection, feature
  enablement, or other operations requiring distinct authorization.
- A request to review a plan is **not** approval to implement it. Explicit human approval
  during plan review can satisfy an ask-first rule before unattended execution. Approval of
  the whole plan counts only when it clearly covers the disclosed restricted operations.
- If approval is missing or ambiguous, ask for scoped approval and report the affected task IDs
  as blocked. Do not call the plan unattended-ready.
- When the human explicitly approves, record that approval in each affected task's
  `description` in `tasks.json`, preserving its implementation requirements and leaving
  `completed: false`. This narrow provenance update is part of the approval workflow, not
  permission to rewrite the plan. Record who approved, what they approved, where the approval
  was given, and any exclusions. Never fabricate approval or infer it from tool permission
  settings, an automated runner, or a request for unattended operation.
- Make the task gate recognize the recorded approval, so a fresh implementing agent does not
  ask again for the same authorized operation. Keep unapproved operations blocked and flag
  contradictory instructions elsewhere in the plan. Material scope changes require renewed
  approval; existing approval is not blanket authorization.
- After recording approval, validate the JSON and review the targeted diff. Respect plan-file
  gitignore rules; do not force-add or commit local plan files.
- Report approval status separately from technical plan quality: **unattended-ready**,
  **blocked pending approval** (with task IDs), or **blocked by other prerequisites**. All
  required approvals and other blocking prerequisites must be resolved for unattended-ready.
  A blocked agent should stop; repeated unattended invocations do not resolve approval gates.

Example task-description addition, only after actual approval:

> Human approval recorded: the user explicitly approved declaring the compound message index
> `{ domainId: 1, userId: 1, createdAt: -1, _id: -1 }` in this plan-review conversation.

### Design Challenge

Judge whether the proposed mechanism is necessary and correctly placed, not just executable.
Keep this proportional: concise evidence and conclusions, not extra plan files or schema fields.

- **Requirements versus mechanisms:** Distinguish user requirements and explicitly agreed
  decisions from planner proposals and unconfirmed assumptions. Do not infer agreement from
  confident specification wording. Check the business meaning of terms such as "completed" or
  "eligible" before accepting a framework status as their definition; inspect code or installed
  dependency behavior to validate the mapping. Identify consequential correctness/scope questions
  requiring confirmation. Do not call the plan implementation-ready or unattended-ready while
  these remain unresolved; report affected tasks as blocked by other prerequisites and ask the
  focused question needed to resolve them. This is not an invented human-approval requirement.
- **Boundary and simpler alternative:** Establish intended execution-surface coverage from the
  feature's required behavior, not from its proposed file list or insertion points. Discover
  relevant callers/entry points in the codebase and trace representative paths to existing shared
  hooks or capabilities. Briefly identify which paths the proposal covers or excludes, citing
  inspected functions/files. If the intended coverage is unstated, ask whether uncovered paths
  should participate; do not assume the proposed boundary defines the feature's scope.
  Can an existing capability or simpler boundary eliminate the largest new mechanism, plumbing,
  or prerequisite refactor? Compare the strongest credible alternative against the requirements,
  not against the proposed implementation's shape. An alternative needing adaptation or having
  different persistence/lifecycle timing is not by itself grounds to reject it: explain whether
  those differences violate a requirement or could be accommodated. Report a supported reason to
  retain or change the design; if no credible alternative applies, explain why briefly. Do not
  manufacture objections or assume fewer lines always means better.
- **Side-effect failure dependencies:** For each new side effect, trace preceding awaited
  operations and enclosing error handling in the actual caller. Could an unrelated rejection
  prevent the effect from running, even if its own errors are caught? Verify that the dependency
  is intentional; where effects must be independent, specify failure-isolation coverage at the
  orchestration boundary. Preserve necessary prerequisites and do not recommend indiscriminate
  error swallowing or parallelization.
- **Test value and ownership:** For each significant behavior, identify the plausible application
  regression and owning test boundary. Flag repeated full-policy assertions across layers unless
  they protect distinct integration/lifecycle risks. Distinguish testing our library configuration
  or contract from retesting library internals. Challenge dedicated exact-log, placeholder-output,
  or trivial-constant assertions unless they protect a contractual, operational, or privacy
  requirement. Preserve justified integration and failure-isolation tests; test count and coverage
  percentage alone do not establish value or validate the intended policy.

### Plan Quality

- **Completeness**: Does tasks.json cover all requirements in context.md?
- **Gaps**: Are there missing tasks? Edge cases discussed but not covered?
- **Ordering**: Are task IDs ordered by dependency (shared/schema types first, then the layers
  that depend on them, per the architecture discovered above)?
- **Granularity**: Are tasks atomic enough? Too large? Too small? Each should take 10-30
  minutes for an agent
- **Plan hygiene**: Is `mytasks/` actually gitignored — no plan files accidentally staged?

### context.md Quality

- **Data structures**: Are they actual type definitions (structs, interfaces, proto messages,
  schema fields — whichever fits the layer) — not prose?
- **File paths**: Are all paths real and verified? Do they match the discovered architecture?
- **Algorithms**: Is pseudocode included for non-trivial logic?
- **Integration points**: Are exact functions, packages, or modules named?
- **Risk**: If the feature touches auth, authorization, or data access, is it classified and
  called out, per the repo's own risk process if it documents one?

### prompt.md Quality

- **Template compliance**: Does it follow the standard template without extra sections or
  workflow steps?
- **Build/test/lint commands**: Does the workflow run the repo's lint command (not just its
  formatter) in addition to build and tests? Do they match commands verified to actually exist for the layer(s)
  this feature touches (not generic guesses)?
- **Important Notes**: Are feature-specific constraints, patterns to follow, and pitfalls to
  avoid clearly and concretely stated (not placeholders)?

### tasks.json Quality

- **Schema**: Does each task have `id`, `title`, `description`, `files`, `completed`?
- **Titles**: Are they action-oriented (5-15 words) naming specific functions, structs,
  components, or schemas?
- **Descriptions**: Are they self-contained paragraphs (3-6 sentences) with concrete types and
  integration points — not restatements of the title, not code dumps?
- **Files**: Are file paths real and verified? Relative to repo root?
- **Shared/schema ordering**: If proto/GraphQL/schema/migration changes exist, are they early
  tasks before tasks that consume the generated/derived code?
- **Layer ordering**: Does task order match the dependency direction between the discovered
  layers (e.g. shared types before backend, backend before frontend)?
- **Working state**: Will the codebase compile/build and tests pass after each individual task?

### Feature Completeness

- Will the feature be fully implemented once all tasks are done?
- Will the application function correctly after implementation?
- Are there integration points, edge cases, or discussed requirements that might be missed?

### Recommendations

- Tasks to add/remove/modify
- Ordering issues to fix
- Risks or concerns

Keep the review focused on the plan's readiness for an implementing agent — don't rewrite the
plan yourself unless the user asks you to. The exception is the narrow recording of explicit
human approval described above; otherwise report findings and let them decide what to fix.
