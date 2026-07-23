---
name: review-plan
description: Review a feature implementation plan (context.md, prompt.md, tasks.json) for completeness and quality
argument-hint: [feature-name]
---

# Review Implementation Plan

Analyze the feature plan for `$ARGUMENTS` for completeness and quality. Companion skill to
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

2. **Review the current code state** in the repo — verify file paths and integration points
   mentioned in the plan exist, and cross-check them against the architecture discovered above

3. **Present an overview covering**:

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
- **Build/test commands**: Do they match commands verified to actually exist for the layer(s)
  this feature touches (not generic guesses)?
- **Important Notes**: Are feature-specific constraints, patterns to follow, and pitfalls to
  avoid clearly and concretely stated (not placeholders)?

### tasks.json Quality

- **Schema**: Does each task have `id`, `title`, `description`, `files`, `completed` (and
  `layer`, if this is a multi-layer repo)?
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
plan yourself unless the user asks you to; report findings and let them decide what to fix.
