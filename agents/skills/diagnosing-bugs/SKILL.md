---
name: diagnosing-bugs
description: Diagnose bugs and regressions by reproducing the exact symptom and tracing it to its source. Continue through a tested fix only when the user asks to fix or resolve it.
---

# Diagnosing bugs

Do not propose a fix until the evidence supports a root cause. A plausible
symptom-level explanation is not enough. Skip a phase only when you can state
why it does not apply.

The requested outcome determines where this workflow stops:

- **Diagnosis only.** For requests to diagnose, investigate, explain, or find the
  cause, stop after confirming the root cause. Report the evidence and likely
  correction without implementing it.
- **Diagnose and fix.** For requests to fix, resolve, or implement the correction,
  continue through Phase 4.

## Protect the evidence

Commands, logs, traces, and captured artifacts may contain credentials or
private data. Redact secrets as `<REDACTED>` before showing them, keep credentials
in environment variables, and quote only the artifact lines that carry the
diagnostic signal. If redacted evidence is insufficient, say what is missing
and ask for the narrowest safe substitute.

## Phase 1: Establish the exact failure and feedback loop

Phase 1 is done when you have a pass/fail signal for the user's exact symptom
that you can run yourself (a focused test, a deterministic CLI invocation, an
HTTP script, a browser check, a trace replay, or a minimal harness), it
reproduces consistently, and you have traced the bad value back to where it
first goes wrong. Record the exact command and observed result, and the paths,
line numbers, error codes, inputs, and environment from the complete error
output. For intermittent failures, raise the reproduction rate by pinning time
or randomness, isolating state, or repeating the trigger rather than guessing.
Check recent and local changes, dependencies, and configuration without
discarding unrelated work. Tag any temporary instrumentation with one unique
`[DEBUG-<id>]` prefix so it can be removed reliably. Read
[root-cause-tracing.md](root-cause-tracing.md) for the tracing procedure.

Before moving on, show the observed failure and current root-cause hypothesis.
For a hard runtime bug, do not advance on conjecture while a red-capable loop is
still feasible. If no agent-runnable loop can be built, list what you tried and
request the missing access, redacted artifact, or permission for temporary
instrumentation.

## Phase 2: Minimize and compare

Shrink a reproducible case one input, caller, configuration value, or step at a
time. Re-run the loop after each cut and keep only what remains load-bearing.
Confirm that the minimized case still shows the user's failure, not a nearby
error.

Then find a similar working path in the same repository. Read the relevant
implementation completely, list meaningful differences, and identify the
dependencies and assumptions that differ between the working and failing paths.

## Phase 3: Test hypotheses

For an ambiguous hard bug, generate three to five ranked, falsifiable
hypotheses and show them to the user before testing. For a narrow failure with
one evidence-backed candidate, state that single hypothesis instead of
manufacturing alternatives.

Test one hypothesis at a time:

1. State the predicted observation or behavior change.
2. Design the smallest experiment that changes one variable.
3. Run it and record the result.
4. If disproved, return to the evidence and form the next hypothesis. Do not
   stack speculative changes.

Prefer debugger or REPL inspection to targeted logs, and targeted logs to broad
logging. For performance regressions, establish a measured baseline and use a
profiler, query plan, or bisection rather than adding timing guesses.

## Clean up the investigation

Before stopping in diagnosis-only mode or entering Phase 4, remove all tagged
instrumentation and throwaway harnesses created during diagnosis. Confirm their
removal by searching for the unique debug prefix. Preserve a minimized
reproducer only when it will become durable regression coverage in Phase 4.

## Phase 4: Fix and verify when requested

1. At the correct public seam, turn the minimized repro into a regression test
   and observe it fail for the expected reason. Follow `tdd` unless an explicit
   exception applies. If no correct seam exists, document that architecture gap
   rather than adding misleading coverage.
2. Make one narrow change at the source of the problem.
3. Run the regression test, the original unminimized feedback loop, and the
   relevant broader checks after the final change.
4. Consider proportionate validation at trust or safety boundaries; read
   [defense-in-depth.md](defense-in-depth.md).

If a fix does not work, isolate or revert only the speculative part and return
to the evidence. When fixes keep failing, question the underlying architecture
or assumption instead of trying another variation.

## Timing failures

Replace arbitrary sleeps with polling for the state or event that matters. Read
[condition-based-waiting.md](condition-based-waiting.md). Retain fixed delays
only when elapsed time is itself the behavior under test, and document the
timing relationship.

## Report

Report the reproduction, evidence, and confirmed root cause in both modes. In
diagnosis-only mode, name the likely correction and stop. In diagnose-and-fix
mode, also report the regression coverage, change made, and fresh verification.
Distinguish unresolved hypotheses from verified facts and name anything that
remains unverified.
