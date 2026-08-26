---
name: prototype
description: Produce a disposable implementation in a throwaway worktree to answer an uncertain logic, interaction, or visual-design question before production work begins.
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

Work in a disposable worktree so the prototype never contaminates the real
branch:

```sh
git worktree add .wt/$(basename "$PWD")-proto-<slug> --detach
```

Build there and report the path. Keep the prototype near the module or route it
is exploring *inside that worktree*, following the repository's existing
layout. Name routes and files so a casual reader cannot mistake them for
production code.

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
and what should now be specified. Keep the worktree available while the user is
still evaluating it. After they confirm it has served its purpose and any
durable decision has been recorded, remove it with `git worktree remove`.

Only preserve the prototype on a throwaway branch when the user asks for that
artifact or it is needed as a primary source for a tracked implementation.
