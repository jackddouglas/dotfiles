---
name: simplify
description: Simplify recently changed code while preserving its exact behavior.
disable-model-invocation: true
---

Run a cleanup-only pass over the scope named by the user, or the current diff
when no scope is given, and apply the useful fixes. Preserve exact behavior:
this is not a bug hunt, feature change, or broad refactor.

Look specifically for:

1. Existing helpers or abstractions the changed code should reuse.
2. Unnecessary complexity, nesting, indirection, or duplication.
3. Inefficient work that can be removed without changing semantics.
4. Abstractions at the wrong altitude: machinery that is too general for its
   use, or low-level detail repeated where one clear local abstraction helps.
5. Names, control flow, and structure that obscure intent.

Prefer readable, explicit code over clever or merely shorter code. Do not
collapse useful boundaries, combine unrelated concerns, add dependencies, or
rewrite untouched areas. Follow the surrounding project's conventions.

After editing, run the repository's relevant formatter and tests. Report the
substantive simplifications, verification results, and anything considered but
left unchanged. If the code is already as simple as it should be, say so and
make no changes.
