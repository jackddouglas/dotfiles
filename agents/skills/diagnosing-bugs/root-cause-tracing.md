# Root-cause tracing

Trace a failure backward from where it appears to where the invalid state first
originates; fixing only the deepest visible symptom leaves other paths broken.
At each caller ask where the suspect value came from and when it first became
invalid, then confirm the source by reproducing the failure from the earliest
bad input or transition. Fix there, and add downstream guards only at a real
trust or safety boundary.

When static inspection is insufficient, add temporary instrumentation before
the dangerous operation (inputs, working directory, relevant environment,
timestamp, stack trace), run once, preserve the evidence, then remove it.

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
