---
name: writing-plans
description: Turn an approved specification or sufficiently clear requirements into a self-contained, testable implementation plan for another engineer or agent.
---

# Writing implementation plans

Use this for multi-step work whose requirements are already decided. If two
reasonable implementations imply different product behavior or architecture,
stop and obtain that decision before planning.

Save the plan in the repository's established planning location. If none
exists, use an ordinary repository Markdown file agreed with the user. Do not
put durable state in harness-private storage.

## Inspect before planning

- Read repository instructions and local changes.
- Map the relevant entry points, data flow, tests, and analogous implementation.
- Record version, platform, dependency, compatibility, and scope constraints
  exactly.
- List files to create or modify and give each a clear responsibility. Follow
  existing structure rather than introducing an unrelated reorganization.

## Task boundaries

Each task should produce one independently testable, reviewable behavior. Fold
setup, scaffolding, configuration, and documentation into the task that needs
them. Split tasks only where a reviewer could reasonably approve one while
rejecting its neighbor.

Use test-driven steps for executable behavior:

1. add one failing behavioral test;
2. run it and record the expected failure;
3. implement the smallest change;
4. run the focused test;
5. refactor while green if needed; and
6. run the relevant broader checks.

Configuration, generated files, and explicitly disposable prototypes follow
their own verification workflow rather than fabricated unit tests.

## Required plan structure

```markdown
# <Feature> implementation plan

**Goal:** <one sentence>
**Approach:** <two or three sentences>
**Constraints:**
- <exact project-wide constraint>

## File map
- `path`: <responsibility>

### Task 1: <reviewable behavior>

**Files:**
- Create: `exact/path`
- Modify: `exact/path:relevant-symbol-or-lines`
- Test: `exact/test/path`

**Interfaces:**
- Consumes: <existing or earlier signatures>
- Produces: <exact signatures later tasks rely on>

- [ ] Add `<test name>` covering <behavior>, with concrete inputs and expected output.
- [ ] Run `<exact command>`; expect <specific failure>.
- [ ] Implement <specific code path and edge handling>.
- [ ] Run `<focused command>`; expect success.
- [ ] Run `<broader command>`; expect success.
```

Give exact paths, symbols, commands, expected outcomes, interfaces, and edge
cases. Include code snippets when a signature, data shape, migration, or subtle
algorithm would otherwise require the implementer to redesign the task.

Do not use `TBD`, “handle errors,” “add validation,” “write tests,” or “similar
to Task N” without the concrete cases and mechanics. A task must be executable
without hidden context from the planning conversation.

## Self-review

Before handoff:

1. Map every requirement to at least one task.
2. Search for placeholders and unstated decisions.
3. Check that signatures and names agree across tasks.
4. Check task ordering and note dependencies explicitly.
5. Ensure each task preserves a working state and has fresh verification.
6. Remove speculative features and unrelated cleanup.

Hand the completed plan to `implementer` for straightforward execution. For
large plans, a fresh worker may execute each independent task, but the parent
must inspect the resulting diff and verify it rather than trusting the report.
