---
name: code-review
description: Review a diff, branch, or pull request from a fresh context for correctness, invariant violations, spec fidelity, repository standards, unnecessary dependencies, duplication, and silent failure.
---

# Code review

## Pin the scope

Resolve the review scope before judging it:

- Use a fixed point, branch, tag, commit, PR, or file set supplied by the user.
- Otherwise review current staged and unstaged changes when present.
- For a committed feature branch, infer the appropriate upstream merge-base
  from repository state and state the ref used. Ask only when multiple plausible
  fixed points would materially change the review.

Confirm that refs resolve and that the resulting diff is not empty. Note the
commit list for a branch review. Do not silently review a different range when
the requested one is unavailable.

## Isolation

Fresh context is the requirement; spawning a subagent is not.

- If the current conversation did not author or previously analyze the diff,
  review it directly. The request and routine inspection do not make the
  context stale.
- If this conversation participated in the change, use the subagent mechanism
  provided by the current harness when available and pass it the resolved scope
  plus the workflow below.
- Otherwise, if the context is not fresh and the current harness provides a
  subagent mechanism, delegate to a fresh context.
- Tell the fresh context that isolation is already provided and it must execute
  the review rather than delegate again.
- Inspect and validate the returned findings before reporting them.
- If fresh isolation is required but unavailable, explain that limitation.

## Gather the contracts

Read surrounding code, not only the diff. Identify:

- repository instructions and coding standards such as `AGENTS.md`,
  `CONTRIBUTING.md`, or language-specific guides;
- the originating issue, specification, plan, or user request, using commit
  references and repository docs when available; and
- relevant tests and invariants in adjacent modules.

If no written spec exists, review against the stated change intent and report
that full spec coverage was unavailable. Do not block the entire review on a
missing setup bundle or issue-tracker integration.

## Workflow

Check in this order:

1. **Correctness.** Does the change do what it claims across error paths,
   boundary values, concurrency, cleanup, and the paths tests miss?
2. **Violated invariants.** What assumptions in surrounding code does the
   change break? Trace callers and consumers outside the diff.
3. **Spec fidelity.** Which requested behaviors are missing, partial, or wrong?
   What was added without being requested? Quote the requirement for each
   spec-based finding.
4. **Repository standards.** Cite the exact documented rule for a hard
   violation. Keep subjective design preferences separate and skip checks that
   formatting or lint tooling already enforces.
5. **Unnecessary dependencies.** Search for equivalent existing capability
   before accepting new packages, imports, or coupling.
6. **Duplicated logic.** Search the repository before concluding that a hunk
   reimplements an existing path.
7. **Silent failure.** Look for swallowed errors, empty handlers, and fallbacks
   that hide an invalid state.

For every candidate finding, try to disprove it by reading the full call path,
tests, and documented constraints. A confident false positive costs more than a
missed preference.

## Report

- Lead with findings ordered by merge-blocking severity, regardless of which
  axis found them.
- Cite `file:line` for every finding and label it `Correctness`, `Invariant`,
  `Spec`, or `Standards` when that provenance matters.
- State the concrete failure mode, not only the code smell or preferred rewrite.
- Separate defects from non-blocking suggestions.
- End with residual risks or tests you could not run.
- If the change is sound, say so plainly and stop; do not manufacture findings.
