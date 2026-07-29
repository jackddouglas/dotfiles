# Defense in depth

After correcting a root cause, consider whether the same invalid state could
reach a dangerous operation through another path. Add validation where each
layer owns a distinct invariant; do not duplicate checks mechanically.

Common layers are:

1. **Input boundary:** reject malformed or untrusted input with an actionable
   error.
2. **Domain boundary:** enforce invariants required by the operation even when
   callers change.
3. **Safety boundary:** prevent destructive or environment-specific operations
   outside their permitted scope.
4. **Observability boundary:** retain enough context to diagnose failures that
   cannot be prevented locally, without logging secrets.

For each proposed guard, identify the bypass or failure mode it catches and
write a test at that boundary when practical. If two checks catch exactly the
same paths and communicate the same error, prefer the single check owned by the
clearest layer.
