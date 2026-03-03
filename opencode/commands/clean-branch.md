---
description: Cleanly reimplement the current branch
---

## Context

- Current bookmarks: !`jj bookmark list`
- Working copy status: !`jj status`
- Commit log: !`jj log -r '::@' --limit 30`
- Trunk: !`jj config get revset-aliases.'trunk()'`

## Task

Reimplement the current branch on a new bookmark with a clean, narrative-quality commit history suitable for reviewer comprehension. This is a jj-colocated git repo -- use `jj` commands for all operations.

**New bookmark name**: Use `$ARGUMENTS` if provided, otherwise `<source-bookmark>-clean`.

### Steps

1. **Identify the base**
   - Determine which bookmark the current branch is based on. Look at the commit log and find the nearest ancestor that is on a tracked bookmark (e.g. `main`, `master`, `develop`, or whatever the trunk is). Use `jj log` to walk the ancestry. Call this the **base bookmark**.
   - Identify the current bookmark name from `jj bookmark list` (the one pointing at `@` or a recent ancestor of `@`).

2. **Validate the working copy**
   - Ensure no uncommitted changes or conflicts exist (`jj status`).
   - If there are problems, stop and report them.

3. **Analyze the diff**
   - Study all changes between the current bookmark and the base bookmark (`jj diff -r '<base>..'`).
   - Form a clear understanding of the final intended state.

4. **Create the clean bookmark**
   - Create a new change on top of the base bookmark: `jj new <base>`
   - Create the new bookmark pointing here: `jj bookmark create <new-bookmark-name>`

5. **Plan the commit storyline**
   - Break the implementation into self-contained logical steps.
   - Each step should reflect a stage of development -- as if writing a tutorial.
   - The sequence should tell a story: a reader stepping through the commits should understand not just *what* changed but *why*, in a natural order.

6. **Reimplement the work**
   - Recreate changes on the clean bookmark, committing step by step.
   - For each logical step:
     - Apply the relevant file changes to the working copy.
     - Describe the change: `jj describe -m '<message>'`
     - Create a new empty change for the next step: `jj new`
   - Each commit must:
     - Introduce a single coherent idea.
     - Include a clear description (imperative mood, ~50 char subject line) with a body explaining the reasoning.

7. **Verify correctness**
   - Diff the final state of the clean bookmark against the source bookmark. They must be identical.
   - Use `jj diff -r '<source-bookmark>..<new-bookmark>'` to confirm no differences.
   - If they differ, fix the discrepancy before proceeding.

8. **Explain the work**
   - Run `/explain` to generate an explanation of the clean bookmark's changes. This helps the author quickly review and understand the narrative that was created.

### Rules

- Never add yourself as an author or contributor.
- Never include "Generated with Claude Code", "Co-Authored-By", or similar attribution lines in commit descriptions.
- The end state of the clean bookmark must be byte-for-byte identical to the source bookmark.
- If the source bookmark has changes that conflict with the base, stop and report the conflicts rather than attempting to resolve them.
- Use `jj` commands for all version control operations. Do not fall back to raw `git` commands.
