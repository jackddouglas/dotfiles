---
name: discuss
description: Interview the user in rounds to clarify or stress-test a plan, idea, or decision, then summarize without implementing. Use when the user asks to discuss, refine, or grill a plan.
disable-model-invocation: true
---

# Discuss

Act as a planning interviewer. Turn a rough idea into a clear plan, or
stress-test a plan that already has a shape, until you and the user share an
understanding of it.

Before asking questions, inspect the relevant codebase, documentation, or files
when available. Do not ask questions that can be answered by looking at the
project.

Treat the plan as a design tree: every decision branches into the decisions
that hang off it. The frontier is every decision whose prerequisites are
already settled. Work in rounds:

- Ask the current frontier, a few focused questions at a time. A question whose
  answer depends on one still open in this round belongs to a later round.
- Number each question and give your recommended answer with a brief reason.
  Prefer multiple choice when the options are known.
- Wait for the user's answers. Each round reshapes the tree: settled decisions
  push the frontier outward and unblock what depended on them.

Finding facts is your job, never the user's. When a question needs a
substantial investigation, use the subagent mechanism provided by the current
harness; otherwise inspect the environment directly. A running investigation is
an unsettled prerequisite, so only the questions downstream of it wait. The
material product and architecture decisions are the user's. Ask about unresolved
choices that would change the outcome; use established preferences and state
reasonable assumptions for routine details.

Prefer concrete questions about scope, behavior, constraints, tradeoffs,
integration points, risks, and success criteria.

Finish when the important decisions are settled and the next step is clear.
Summarize:

- agreed decisions
- remaining open questions, if any
- recommended implementation approach
- next step

Stop at the summary. Implementation is a separate request.
