---
name: test-driven-development
description: Implement executable behavior changes with a red-green-refactor cycle that proves each test can detect the missing or broken behavior.
---

# Test-driven development

For features and bug fixes, write one behavioral test first, observe the
expected failure, then write the minimum production code to make it pass. For a
pure behavior-preserving refactor, establish passing coverage of the behavior
before editing, refactor, and confirm the same coverage still passes.

## Explicit exceptions

- A task using the `prototyper` skill is disposable exploration: do not add
  tests there. Throw the prototype away, then restart production work with TDD.
- Generated code should be verified at its generator or consumer boundary.
- Pure documentation and configuration changes use relevant structural or
  integration checks instead of fabricated unit tests.
- If the repository cannot support an automated regression test, explain why
  and agree on a one-off reproducer or manual check before implementing.

These exceptions do not cover ordinary production behavior merely because a
test is inconvenient.

## Red

1. Name the observable break the test will catch.
2. Write the smallest test for one behavior, using real code where practical.
3. Derive expected values independently of the implementation.
4. Run the focused test and confirm that it fails—not errors—for the expected
   missing or broken behavior.

If it passes immediately, the test does not demonstrate the new requirement.
Revise it or establish that the behavior already exists.

## Green

1. Write the simplest production change that satisfies the failing test.
2. Do not add unrelated features, generalized options, or refactors.
3. Run the focused test and then relevant nearby tests.
4. Fix production code rather than weakening a valid expectation.

## Refactor

Only after green, remove duplication and improve names or structure while
preserving behavior. Keep rerunning the relevant tests.

Repeat the cycle for the next behavior. Read `writing-good-tests.md` whenever
adding or changing tests, mocks, fixtures, or test-only helpers.

## Existing implementation written before a test

Do not pretend a later test is test-first. If the code is new and can be safely
recreated, set it aside or revert it, write and observe the failing test, then
implement from that requirement. If discarding existing work would destroy
unrelated user changes, preserve it and be explicit that the resulting test is
characterization or regression coverage rather than a verified red-green
cycle.

## Completion checklist

- Every changed behavior has regression coverage or a documented exception.
- Each test for new or corrected behavior was observed failing for the expected
  reason; characterization coverage for a pure refactor passed before and after.
- Focused and broader tests pass after the final implementation.
- Tests assert observable behavior, not implementation trivia or mock presence.
- Mocks replace only genuinely slow, external, or uncontrollable boundaries.
- The production diff contains no test-only API or speculative behavior.
