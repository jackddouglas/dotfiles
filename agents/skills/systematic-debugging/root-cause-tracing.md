# Root-cause tracing

Trace a failure backward from where it appears to where the invalid state first
originates. Fixing only the deepest visible symptom leaves other paths broken.

## Procedure

1. **Observe the symptom.** Capture the exact operation, inputs, output, and
   stack trace.
2. **Find the immediate cause.** Identify the statement that directly produces
   the failure.
3. **Inspect its caller.** Determine which values were passed and what
   assumptions the callee made.
4. **Continue upward.** At each caller ask where the suspect value came from and
   when it first became invalid.
5. **Confirm the source.** Reproduce the failure by controlling the earliest
   bad input or state transition.
6. **Fix there.** Add downstream guards only where they protect a real trust or
   safety boundary.

When static inspection is insufficient, add temporary instrumentation before
the dangerous operation. Include inputs, current directory, relevant
environment, timestamp, and a stack trace. Run once, preserve the evidence,
then remove noisy instrumentation unless it has durable operational value.

For test pollution, bisect the test set or run suspect tests individually until
the first test that leaves invalid global state is identified. Verify the
polluter in isolation and in sequence with a test that observes the pollution.

A useful trace can be written as:

```text
visible failure
<- immediate invalid operation
<- bad argument or state
<- caller that supplied it
<- earliest invalid transition (root cause)
```
