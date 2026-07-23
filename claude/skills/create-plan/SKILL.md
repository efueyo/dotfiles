---
name: create-plan
description: Create an implementation plan (context.md, prompt.md, tasks.json) for a feature after discussing it with the user
---

# Create Implementation Plan

Based on our discussion, create the implementation plan for this feature.

## Discover Project Architecture First

Don't assume a language, layer split, or toolchain — this skill runs in many different repos.
Before writing anything:

- Read `CLAUDE.md`, `AGENTS.md`, and `README.md` at the repo root (and in relevant
  subdirectories) for documented architecture, layers, and build/test/lint commands.
- If those are missing or incomplete, explore: `package.json`/`go.mod`/`Cargo.toml`/
  `pyproject.toml`, `Makefile`/`justfile`/`turbo.jsonc`/`Taskfile.yml`, and the directory
  structure (`apps/`, `packages/`, `server/`, `web/`, `src/`, `cmd/`, `internal/`, `shared/`,
  `proto/`, etc.) to infer the layers/workspaces.
- If the repo is a monorepo with independent layers (e.g. a Go server + a TypeScript client, or
  multiple workspace packages), note each layer's language, location, build command, test
  command, and lint/format command — you'll need these for prompt.md.
- **Verify every command before writing it down.** Check it actually exists (a script in
  `package.json`, a target in the `Makefile`, a recipe in the `justfile`) rather than assuming
  a common one like `make test` exists just because it's common elsewhere.
- If the repo has its own skill/command for writing plans, UI-specific implementation plans, or
  commit/PR conventions, prefer that repo's own guidance over this skill's generic defaults for
  those parts — this skill is the fallback when the repo doesn't already have one.

## What to Capture from Our Discussion

Before writing the plan, review our conversation and extract:

### Design Decisions

- What approach did we agree on? Document the "what" and "why"
- Were there trade-offs discussed? Note what we prioritized

### Rejected Alternatives

- What approaches did we consider but NOT choose?
- Why were they rejected? (complexity, performance, scope, etc.)
- Include these in context.md's "Future Considerations" or a dedicated section

### Constraints and Requirements

- User-specified constraints ("must be server-authoritative", "no breaking changes")
- Performance requirements ("< 10ms per tick", "O(n) complexity")
- Compatibility requirements ("works with existing X system")

### Formulas and Algorithms

- Any formulas we agreed on (capture exactly as discussed)
- Algorithms or pseudocode we sketched out
- These go in context.md AND may need to be repeated in prompt.md for quick reference

### Edge Cases

- Edge cases we explicitly discussed
- How each should be handled
- These become tasks with test requirements

### Scope Boundaries

- What's explicitly IN scope for this feature
- What's explicitly OUT of scope (goes to Future Considerations)

### Risk

- If the repo documents a security/risk classification process (check `CONTRIBUTING.md` /
  `AGENTS.md`), classify this feature accordingly and record it in context.md — auth,
  authorization, and data-access changes deserve extra scrutiny even without a formal process

---

## Instructions

1. **Determine feature name**: Use the argument provided, or derive a kebab-case name that
   describes the feature (e.g., `fog-of-war`, `contact-export`, `task-scheduling`)

2. **Create directory**: `mytasks/active/{feature-name}/`

3. **Create three files** following the specifications below:


---

### context.md

A specification document that gives an implementing agent everything it needs to understand
the feature without asking questions. Write it in markdown with these sections:

```markdown
# {Feature Name}

## Overview

Brief description of what this feature does.

## Why This Feature

### Problem

What issue does this solve? What's wrong with current behavior?

### Solution

High-level approach to solving the problem.

### Success Criteria

- Bullet points of measurable outcomes
- Include performance targets if applicable

## Specification

### {Subsection for each major component}

Detailed specification with:

- Data structures, in the actual language/schema of the layer being modified (structs,
  interfaces, proto messages, database schema fields — whatever applies)
- Algorithms (pseudocode if complex)
- State changes
- Rules and edge cases

## Technical Considerations

### Performance

- Big-O complexity estimates
- Optimization strategies
- Target metrics

### Edge Cases

Numbered list of edge cases and how they're handled.

## Existing Infrastructure

What already exists in the codebase that this feature builds on.

## Files to Modify

Table of files and their purpose in this feature.
(Verify these by exploring the codebase before listing)

## Future Considerations

What's explicitly out of scope but could be added later.
```

#### Level of Detail for context.md

The specification must be **implementation-ready** — an agent should be able to write code
from it without guessing. This means:

- **Data structures**: Write actual type definitions in the language of the layer being
  modified — a Go struct, a TypeScript interface, a proto message, a SQL column list —
  whichever fits. Never use prose like "a structure with fields for X and Y".
- **Algorithms**: Include pseudocode or step-by-step logic for anything non-trivial.
- **File paths**: Use real paths verified by exploring the codebase, not guesses.
- **Integration points**: Name the exact functions, packages, or modules being modified.

**Good — implementation-ready (concrete types, real file path, real integration point):**

````markdown
### Rate Limiter

Add to `src/rate-limit/limiter.ts`:

```typescript
export class Limiter {
  private hits = new Map<string, number[]>(); // key -> request timestamps (ms)

  constructor(private windowMs: number, private maxRequests: number) {}

  allow(key: string): boolean {
    // 1. Filter out timestamps older than windowMs for this key
    // 2. If the remaining count >= maxRequests, store the pruned list and return false
    // 3. Otherwise push Date.now(), store it, and return true
  }
}
```

Wire it into `src/http/middleware.ts`'s existing middleware chain, keyed by client IP.

Performance target: O(k) per request where k = requests in the current window; prune lazily
on each call, not on a background timer.
````

**Bad — too vague, forces the agent to make design decisions:**

```markdown
### Rate Limiting

We need to rate limit requests. It should be efficient and configurable.
```

**Bad — over-specified, includes full implementation instead of specification:**

````markdown
### Rate Limiter

```typescript
export class Limiter {
  allow(key: string): boolean {
    const now = Date.now();
    const timestamps = (this.hits.get(key) ?? []).filter((t) => now - t < this.windowMs);
    // ... 40 more lines of implementation
  }
}
```
````

---

### prompt.md

Agent instructions that tell an implementing agent how to work through the tasks. Use this
template, replacing `{feature-name}`, the build/test commands (from "Discover Project
Architecture" above), and the Important Notes section:

```markdown
Read @mytasks/active/{feature-name}/context.md to understand what we are building.

Check `mytasks/active/{feature-name}/tasks.json` for the next incomplete task (first item where `completed` is `false`).

## Scope Rules

This agent works ONLY on tasks in `mytasks/active/{feature-name}/tasks.json`. You MUST:

1. **Only work on tasks** listed in the tasks.json file for this feature.
2. **Skip unrelated work** — if you find type errors, bugs, or tech debt outside this feature's scope, ignore them. Do not create tasks for them, do not fix them.

## Stop Conditions

**STOP IMMEDIATELY and exit** (do not continue looking for work) if:

- All tasks in tasks.json have `completed: true`
- There are no remaining incomplete tasks

When stopping, report what you checked and the current feature status. Do NOT invent work.

## Task Workflow

**Complete exactly ONE task, then exit.**

Your job is to:

1. Pick the first incomplete task from tasks.json (first item where `completed` is `false`)
2. Implement that task
3. Add tests when necessary
4. Ensure that the code compiles/builds: {verified build command(s) for this feature's layer(s)}
   4b. If this task changes a schema or IDL (proto/GraphQL/OpenAPI/etc.), run the repo's codegen command and include all regenerated files in the commit
5. Ensure that tests pass: {verified test command(s) for this feature's layer(s)}
6. Mark the task as completed in tasks.json (set `completed: true`)
7. Commit your changes with a one line message, e.g. `feat(feature): description`
8. **Exit immediately** — do NOT pick up another task

**If you discover additional work needed** (edge cases, refactoring, missing pieces) that is directly related to the current task, add a new task entry to tasks.json with the next sequential id.

You can read the previous commits and the codebase if you need to verify what has been implemented so far.

## Important Notes

- {Feature-specific constraints, e.g., "no breaking changes to the public API"}
- {Patterns to follow, e.g., "follow the existing handler pattern in X"}
- {Things to avoid, e.g., "never bypass the existing validation layer"}
- {Ownership/risk notes from the discussion, if any}
```

#### Level of Detail for prompt.md

The prompt.md template above is mostly fixed. The parts you customize are:

- **Build/test commands** (steps 4 and 5): Use the commands verified in "Discover Project
  Architecture" — scoped to the layer(s) this feature actually touches, not the whole repo if
  the repo supports scoped commands.
- **Important Notes**: 2-5 bullet points covering architectural constraints, existing patterns
  to follow (name specific files), pitfalls to avoid, and any ownership/risk notes.

Do NOT add extra workflow steps, modify the task workflow, or add sections beyond what the
template defines.

---

### tasks.json

A JSON file containing an array of task objects. Each task represents one unit of work that an
agent completes in a single session.

#### Schema

```json
[
  {
    "id": 1,
    "title": "Short action-oriented title naming specific functions or components",
    "description": "A paragraph explaining what to implement. Includes: what to create/modify, the approach to use, key details like data structures or algorithms involved, and how it integrates with existing code. Should be self-contained — the agent reads this + context.md and can start coding.",
    "files": ["path/to/file1.ts", "path/to/file2.tsx"],
    "completed": false
  }
]
```

Fields:

- **id**: Sequential integer starting at 1
- **title**: Action-oriented name (5-15 words). Names the specific function, struct, component,
  or schema being built
- **description**: One paragraph (3-6 sentences) explaining what to do and how. Mentions
  concrete types, method names, and integration points. Self-contained enough that an agent can
  start coding after reading this + context.md
- **files**: Array of file paths (relative to repo root) that this task will create, delete, or
  modify. Must be real paths verified by exploring the codebase
- **completed**: Always `false` when creating the plan

If the repo is a monorepo with multiple independent build/test layers (discovered above), add a
**layer** field (e.g. `"layer": "server"` / `"layer": "web"`) so the implementing agent knows
which build/test command applies without re-deriving it.

#### Level of Detail for tasks.json

Each task must be **specific enough to implement without design decisions** but **not so
granular that it becomes a line-by-line script**.

**Good title — names the concrete deliverable:**

```
"Add token-bucket Limiter class with per-key request pruning"
```

**Bad title — too vague, could mean anything:**

```
"Implement rate limiting"
```

**Bad title — too granular, micromanages:**

```
"Add Map import in limiter.ts line 5"
```

**Good description — actionable, self-contained:**

```
"Create a Limiter class in src/rate-limit/limiter.ts that tracks request timestamps per key in a Map<string, number[]>. allow(key) filters out timestamps older than windowMs, returns false if the remaining count is >= maxRequests, otherwise pushes Date.now() and returns true. Wire it into the existing middleware chain in src/http/middleware.ts, keyed by client IP."
```

**Bad description — restates the title without adding useful information:**

```
"Implement the rate limiter. It should limit requests per key using a time window."
```

**Bad description — writes the code instead of describing the task:**

```
"Create limiter.ts with: export class Limiter { allow(key: string) { const now = Date.now(); ... } }"
```

#### Task Ordering and Sizing

- **Order by dependency**: If task B imports types defined in task A, task A must have a lower id
- **Shared/schema types first**: If a feature adds or modifies shared types (proto messages, GraphQL schema, database migrations), that must be its own early task so generated/derived code is available for later tasks
- **One session per task**: Each task should take 10-30 minutes for an agent. If it would take longer, split it
- **Working state after each task**: The codebase must compile/build and tests must pass after each task is completed
- **Target 15-30 tasks** for a medium feature. Fewer for small features, more for large ones
- **Group by layer**: shared/schema definitions first, then server-side/backend logic, then client-side/frontend integration, then tests

---



## Quality Checklist

Before finishing, verify:

- [ ] context.md covers all design decisions from our discussion
- [ ] context.md has actual type definitions (structs, interfaces, proto messages, schema fields — whichever fits the layer) — not prose
- [ ] context.md file paths were verified by exploring the codebase
- [ ] prompt.md uses the template exactly, only customizing build/test commands and Important Notes
- [ ] prompt.md's build/test commands were verified to actually exist in this repo
- [ ] tasks.json has sequential IDs and all tasks start with `completed: false`
- [ ] Shared/schema type changes (if any) are their own early task, before tasks that consume the generated/derived code
- [ ] Task ordering respects dependencies (foundational tasks first)
- [ ] Each task title names a specific function, struct, component, or schema
- [ ] Each task description is a self-contained paragraph (3-6 sentences)
- [ ] Each task's files array contains real, verified paths
- [ ] Edge cases from discussion are captured as tasks
- [ ] Risk is classified in context.md if the feature touches auth, authorization, or data access
