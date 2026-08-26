---
name: research
description: Evaluate an external library, API, or protocol and produce a source-backed technical brief with alternatives and codebase fit.
---

# Research

## Isolation

Fresh context is the requirement; spawning a subagent is not.

- If the current conversation has no prior work on the subject being researched,
  it is already fresh. Execute the workflow below directly. The user's request
  and routine repository inspection do not make it stale. Do not spawn a
  subagent merely to satisfy this section.
- If this conversation participated in designing, implementing, or previously
  analyzing the subject, use the subagent mechanism provided by the current
  harness when available.
- Otherwise, if the context is not fresh and the current harness provides a
  subagent mechanism, delegate to a fresh context.
- Pass the user's request and the workflow below to the fresh context. Tell it
  that isolation is already provided and it must research directly rather than
  delegate again.
- Wait and inspect the cited result before relaying it.
- If the context is not fresh and no isolation mechanism is available, explain
  that limitation instead of presenting context-biased work as independent.

## Workflow

Produce a technical brief on an external library, API, or protocol. Cover:

- **What it is** and the problem it solves. One paragraph.
- **How it is actually used.** Real call signatures, configuration, and the
  smallest working example.
- **Constraints.** Version requirements, platform limits, license, maintenance
  status, and known sharp edges.
- **Alternatives**, and why to choose this over them or not.
- **Fit.** How it would land in this codebase given what is already here.

Rules:

- Every non-obvious claim carries a source: a URL or `file:line` for local code.
- Prefer primary sources. Official documentation and source beat secondary
  write-ups; inspect source when documentation is thin or suspect.
- Distinguish verified facts from inference, and label inference explicitly.
- Report versions actually observed rather than versions recalled from memory.
- When sources conflict, say so and explain which source is more authoritative.
- If the question is underspecified, answer the most useful reading and state
  which reading you took.

The brief is the deliverable. Write it to the repository only when the user
asked for a durable file or the task explicitly requires a handoff artifact;
otherwise return it in the conversation. When writing, follow the repository's
existing research-note convention and say where the file was saved.
