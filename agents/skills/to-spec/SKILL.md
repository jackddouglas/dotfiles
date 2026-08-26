---
name: to-spec
description: Turn the current conversation and codebase context into a durable specification, publishing it to the configured issue tracker or repository spec location.
disable-model-invocation: true
---

# Turn the conversation into a spec

Synthesize what has already been decided. Do not restart discovery or conduct a
new interview. Inspect the repository when needed to make the current state,
existing interfaces, vocabulary, tests, and constraints accurate.

If a material product or architecture decision is still unresolved, record it
under **Open questions** rather than silently choosing. Ask only when the user
explicitly wants a decision-complete spec and the missing choice cannot be
inferred safely.

## Process

1. Read repository instructions, relevant domain glossaries and ADRs, and the
   implementation area discussed in the conversation.
2. Map the proposed behavior onto existing public seams and test patterns.
   Prefer the highest existing seam that can observe the behavior. Propose a new
   seam only when the existing interface cannot express the requirement.
3. Write a complete but proportionate spec using the template below. Use domain
   language rather than transient internal names.
4. Publish it using the repository's documented issue-tracker workflow when one
   exists. Apply a readiness label only when that label is documented.
   Otherwise use the existing spec or planning directory; if there is no
   convention, save it as `docs/specs/<descriptive-slug>.md`.
5. Report the destination and any unresolved questions. Do not claim the spec
   is decision-complete while open questions remain.

## Template

```markdown
# <Feature or change> specification

## Problem

The user-visible or operational problem, including who encounters it and the
evidence that it exists.

## Desired outcome

What becomes possible or reliably true when the work is complete.

## Behavior and acceptance criteria

A numbered set of observable scenarios, including relevant success, failure,
permission, lifecycle, compatibility, and recovery cases. Use user stories only
when an actor, goal, and benefit clarify the requirement.

## Implementation decisions

The modules and interfaces affected, data or schema changes, contracts,
invariants, interactions, and decisions already made. Avoid exact file paths or
large code snippets that will go stale. A small prototype-derived type, state
machine, or schema may be included when it records a settled decision more
precisely than prose.

## Testing decisions

The public seams to test, the behavior each test must detect, analogous tests in
the repository, and any required integration or manual verification.

## Out of scope

Explicit exclusions and tempting adjacent work that this change will not do.

## Open questions

Only unresolved decisions that materially affect behavior, architecture, or
scope. Write `None` when the spec is decision-complete.
```
