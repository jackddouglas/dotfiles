---
name: receiving-code-review
description: Evaluate code-review feedback against the repository, then implement accepted items only when the user asks to address or apply the feedback.
---

# Receiving code review

Treat review as technical input, not an instruction to agree performatively.

The requested outcome determines whether this skill edits:

- **Evaluate only.** If the user asks whether feedback is correct, classify each
  item, explain the evidence, and stop before editing.
- **Address feedback.** If the user asks to address, apply, or resolve the
  feedback, evaluate first and then implement accepted items.

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
6. In address-feedback mode, implement accepted items one at a time, ordered by
   correctness/security blockers, simple isolated changes, then broader
   refactors.
7. In address-feedback mode, test each change and run regression checks for the
   complete set.

Before accepting a request to “do it properly,” search for actual callers and
requirements. Do not add unused machinery merely to satisfy an abstract notion
of completeness.

Acknowledge correct feedback by naming the issue and the concrete fix. Avoid
empty agreement before verification. If your initial pushback was wrong, state
what evidence corrected it and proceed without defensiveness.

When replying to an inline GitHub review comment, reply in that comment's
thread rather than creating an unrelated top-level PR comment.
