---
name: brainstorming
description: Turn an idea into a design before any code exists, by interviewing for intent, proposing alternatives, and naming what was rejected.
---

# Brainstorming

You are turning an idea into something specific enough to build. The design is
the deliverable. No code, no scaffolding, no files created yet.

Put the design in front of the user before the code: two or three approaches
with their trade-offs, your recommendation, and what you rejected and why. This
is an offer, not a gate. If the user would rather go straight to
implementation, do that and do not raise it again.

## Read the ground first

Check the current state—files, docs, recent commits—before asking anything. A
question you could have answered by reading spends the user's attention, which
is the scarce resource here.

If the request spans several independent subsystems, say so immediately and
help decompose it. Refining the details of a project that needs splitting is
wasted work. Design the first piece; the rest get their own passes.

## Interview

One question per message. Prioritize questions whose answer would change the
architecture, and skip the ones where a sensible default exists—state the
default you took instead. Prefer multiple choice when the options are known.

Match the ritual to the kind of ignorance in the room:

- The user knows what they have not resolved: interview them.
- The user will know it when they see it: build two or three divergent versions
  with `prototyper` and let them react. Describing alternatives does not
  surface taste; reacting to them does.
- The user does not know what they do not know: offer a blindspot pass. Survey
  the area, find the unknown unknowns, and teach them before designing. Use
  `researcher` when the territory is unfamiliar to you as well.

## Present

Scale each section to its complexity: a sentence when it is straightforward, a
few paragraphs when it is genuinely nuanced. Cover architecture, boundaries,
data flow, failure handling, and how it will be tested. Check in after each
section rather than delivering the whole design at once.

Cut ruthlessly. Every feature that is not needed is one the user has to review,
maintain, and eventually delete.

Design for units that can be understood and tested alone: one clear purpose, a
stated interface, an obvious dependency list. If you cannot say what a unit
does without describing its internals, the boundary is wrong.

In an existing codebase, follow existing patterns and fold in the targeted
cleanup this work genuinely needs. Do not propose unrelated refactoring.

## Hand off

Write the agreed design where the repository keeps such documents, or in an
ordinary Markdown file agreed with the user. Then hand to `writing-plans`.
Do not implement directly from the design; the plan is what makes it executable
and reviewable.
