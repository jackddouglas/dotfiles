---
name: receiving-code-review
description: Evaluate code-review feedback against the repository before implementing it, clarifying ambiguity and pushing back with evidence when a suggestion is incorrect or out of scope.
---

# Receiving code review

Treat review as technical input, not an instruction to agree performatively.

## Workflow

1. Read all feedback before editing.
2. Restate the technical requirement in concrete terms. If any related item is
   ambiguous, ask before partially implementing the set.
3. Inspect the referenced code, surrounding invariants, tests, supported
   platforms, and reasons for the current implementation.
4. Classify each item as correct, incorrect, already addressed, a preference,
   or requiring a product or architecture decision.
5. Push back on incorrect or unnecessary suggestions with code, tests, or
   documented constraints. Escalate conflicts with prior user decisions.
6. Implement accepted items one at a time, ordered by correctness/security
   blockers, simple isolated changes, then broader refactors.
7. Test each change and run regression checks for the complete set.

Before accepting a request to “do it properly,” search for actual callers and
requirements. Do not add unused machinery merely to satisfy an abstract notion
of completeness.

Acknowledge correct feedback by naming the issue and the concrete fix. Avoid
empty agreement before verification. If your initial pushback was wrong, state
what evidence corrected it and proceed without defensiveness.

When replying to an inline GitHub review comment, reply in that comment's
thread rather than creating an unrelated top-level PR comment.
