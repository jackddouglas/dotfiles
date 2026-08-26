---
name: prototype
description: Produce a disposable logic or UI implementation in isolated temporary state to answer an uncertain design question before production work begins.
---

# Prototype

A prototype is throwaway code that answers one question. Its job is to make the
real requirement visible, turning “I will know it when I see it” into something
concrete to react to.

## Choose the artifact

State the question before writing code, then choose the smallest artifact that
can answer it:

- For business logic, state transitions, or data shape, read [LOGIC.md](LOGIC.md)
  and build a single shareable HTML demo.
- For appearance, layout, or interaction taste, read [UI.md](UI.md) and build
  two or three structurally different variants in the surrounding application.
- For another kind of uncertainty, build only the executable slice that exposes
  it and state why neither standard branch fits.

If the question is ambiguous, infer from the surrounding code when the choice
is low-risk; otherwise ask before building the wrong artifact.

## Isolate it

Use the lightest isolation that fits the artifact:

- **Standalone logic prototype.** Put the self-contained HTML file in a unique
  OS temporary directory outside the repository. Report the exact path. A logic
  demo does not need a Git worktree unless its question genuinely depends on the
  repository's build or runtime.
- **Repository-backed UI or other executable slice.** Inspect the working tree
  first and record the exact base revision. State whether the prototype uses
  committed `HEAD` or also needs selected uncommitted changes. Create a unique
  disposable worktree outside the primary checkout. If relevant state is
  uncommitted, materialize only that state in the worktree without stashing,
  resetting, or otherwise changing the primary checkout. If that cannot be done
  safely, stop and ask which source state to prototype.

For a repository-backed prototype, keep files near the module or route they
explore inside the worktree and follow the repository's existing layout. Name
routes and files so a casual reader cannot mistake them for production code.
Always report the artifact or worktree path and whether this task created it.

## Rules

- Optimize for the fastest honest signal. Hardcode, stub, fake data, and skip
  error handling, then disclose those shortcuts.
- Build the uncertain part. Skip the part that is merely implementation work.
- Make it trivial to run and surface all state needed to judge the answer.
- Use in-memory or clearly disposable state. Do not perform real mutations or
  depend on production services unless that is the question being tested and
  the user has authorized it.
- Do not write tests, handle edge cases, generalize, or refactor. Restart the
  validated production behavior under `tdd` rather than promoting prototype
  code unchanged.
- When the answer is a matter of taste, make the variants meaningfully
  different. Color-only variations do not expose a design decision.

End by naming the question, what the prototype revealed, the shortcuts it took,
and what should now be specified. Keep the temporary artifact or worktree
available while the user is still evaluating it. After they confirm it has
served its purpose and any durable decision has been recorded, remove only the
temporary state created by this task; verify a worktree is clean before using
`git worktree remove`.

Copy a standalone logic artifact to a durable location only when the user asks
to preserve it. Preserve a repository-backed prototype on a throwaway branch
only when the user asks for that artifact or it is needed as a primary source
for a tracked implementation.
