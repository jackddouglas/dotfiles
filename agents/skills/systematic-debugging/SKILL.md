---
name: systematic-debugging
description: Investigate bugs, test failures, build failures, performance problems, and unexpected behavior by finding and testing the root cause before changing production code.
---

# Systematic debugging

Do not propose a fix until the evidence supports a root cause. A plausible
symptom-level explanation is not enough.

## Phase 1: Establish the failure

1. Read the complete error, warning, and stack trace. Record exact paths, line
   numbers, error codes, inputs, and environment details.
2. Reproduce the failure consistently. If it is intermittent, gather more data
   instead of guessing.
3. Inspect recent and local changes, dependency changes, configuration, and
   environment differences without discarding unrelated work.
4. In a multi-component path, instrument each boundary once: log what enters,
   what exits, and which configuration is visible. Use the evidence to locate
   the failing component.
5. Trace bad values backward through callers until you find where they first
   become wrong. See `root-cause-tracing.md`.

Before moving on, state the observed failure and current root-cause hypothesis.

## Phase 2: Compare patterns

1. Find a similar working example in the same repository.
2. Read the relevant reference implementation completely.
3. List meaningful differences between the working and failing paths.
4. Identify the dependencies and assumptions each path relies on.

## Phase 3: Test one hypothesis

1. State one falsifiable hypothesis: “I think X causes the failure because Y.”
2. Design the smallest experiment that changes one variable.
3. Run it and record the result.
4. If disproved, return to the evidence and form a new hypothesis. Do not stack
   speculative changes.

When you do not understand part of the system, say so and inspect or research
it before continuing.

## Phase 4: Implement and verify

1. For executable behavior, create the smallest regression test or reproducer
   and observe it fail for the expected reason. Follow `test-driven-development`
   unless an explicit exception applies.
2. Make one narrow change at the source of the problem.
3. Run the regression test and the relevant broader checks.
4. Follow `verification-before-completion` before claiming the issue is fixed.
5. After fixing the source, consider proportionate validation at trust or
   safety boundaries; see `defense-in-depth.md`.

If a fix does not work, revert the speculative part or otherwise keep the next
experiment isolated, then return to Phase 1 with the new evidence. After three
failed fix attempts, stop and discuss whether the underlying architecture or
assumption is wrong rather than attempting a fourth variation.

## Timing failures

Replace arbitrary sleeps with polling for the state or event that matters.
Retain fixed delays only when elapsed time is itself the behavior under test,
and document the timing relationship. See `condition-based-waiting.md`.

## Stop signals

Return to Phase 1 when you catch yourself:

- proposing solutions before reproducing or tracing the failure;
- saying “probably” and editing immediately;
- changing several variables in one experiment;
- treating a passing narrow test as proof that the full issue is fixed;
- adding a timeout without identifying the condition being awaited; or
- trying one more variation after repeated failed fixes.

## Report

Report the reproduction, evidence, confirmed root cause, regression coverage,
change made, and fresh verification. Distinguish unresolved hypotheses from
verified facts.
