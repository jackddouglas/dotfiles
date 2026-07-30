---
name: dispatching-parallel-agents
description: Run independent tasks concurrently in fresh contexts, then reconcile the results rather than trusting the reports.
---

# Dispatching parallel agents

Use this for two or more tasks that share no state and no ordering. Parallelism
buys wall-clock time and independent perspective. It costs you sight of what
each worker actually did, so the reconciliation at the end is not optional.

## When it applies

- **Independent.** No worker needs another's output.
- **Non-overlapping.** No two workers write the same file.
- **Worth isolating.** Each task is large enough that a fresh context helps.

If the tasks are sequential, or they touch the same files, run them in order.
Concurrent writes to one file cost more to untangle than the time saved.

## Dispatch

- Give each worker the complete task. It cannot see this conversation, and a
  worker left to guess at context will invent it.
- State the deliverable and its shape. "Report each finding as `file:line` with
  a one-line claim" beats "look into the error handling".
- Say what is out of scope, especially what it must not edit.
- Give each worker its own worktree where they would otherwise collide on the
  filesystem.
- Launch them in one batch. Dispatching serially and waiting between each
  forfeits the only thing you came for.

## Diverse workers beat identical ones

When the question is "did we miss anything", give each worker a different
lens—correctness, security, performance, does-it-reproduce—rather than running
one prompt several times. Redundancy finds the same thing repeatedly; diversity
finds different things.

## Reconcile

A worker's report is a claim, not a result.

- Read the actual diff or output, not the summary of it.
- Run the checks yourself. See `verification-before-completion`.
- Where two workers disagree, resolve it in the code rather than by averaging.
- Deduplicate before reporting. Three workers finding one bug is one bug.
- Name the tasks that failed or returned nothing. Silent omission reads as
  coverage.

Report what you verified and what you are relaying on trust, and keep the two
separate.
