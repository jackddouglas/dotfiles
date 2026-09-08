---
name: writing-plans
description: Turn an approved specification or sufficiently clear requirements into a self-contained, testable implementation plan for another engineer or agent.
---

# Writing implementation plans

Use this for multi-step work with decided requirements. Resolve choices that
change product behavior or architecture before planning. Read repository
instructions and local changes, then inspect relevant code, tests, and patterns.
Save the plan in the repository's planning location, or an ordinary Markdown
file agreed with the user.

## Write for an engineer

Explain what changes, why the approach fits, how it works, and how to verify it
in connected prose. Weave exact paths, symbols, interfaces, and edge cases into
the explanation. Prefer stable symbols over line numbers; include code when
it prevents ambiguity about a signature, data shape, migration, or algorithm.

Write for humans and agents. Link an existing specification when it defines
enduring behavior. Use lists, tables, or code blocks where they clarify the work.

Include the context and design decisions needed for implementation. Specify
concrete cases and mechanics for error handling, validation, and tests.

## Organize the work

Open with the problem, intended outcome, approach, main tradeoff, and exact
scope and compatibility constraints. A before/after example can make this brief.

Give each task an outcome-based heading and explain:

- What it enables, why it comes here, and dependencies on earlier tasks.
- Which files and symbols change, their responsibilities, and the mechanism.
- How to verify the behavior: test paths, concrete inputs and outputs, exact
  commands, and expected results.

Each task should deliver one independently testable, reviewable behavior and
preserve a working state. Fold setup and documentation into the task that needs
them. Use one completion checkbox per task with an observable acceptance condition.

For executable behavior, plan a failing behavioral test, the smallest change,
and focused verification; refactor while green as needed. State the expected
initial failure. Configuration, generated files, and disposable prototypes use
appropriate checks. Put broader checks at
integration checkpoints and give shared final checks once, including necessary
platform or manual verification. Distinguish expected results from checks
actually run during planning.

## Review and handoff

Check requirement coverage, task order, interface consistency, and verification.
Remove placeholders, unstated decisions, speculative features, and unrelated
cleanup. Read the plan in order: does the explanation flow, and can an engineer
implement it without guessing?

After saving, walk the user through one coherent task or section at a time,
explaining behavior, rationale, and tradeoffs. Pause after each for questions
or corrections before continuing. Hand the completed plan to an implementation
run; if workers execute separate tasks, inspect their diffs and verify results.
