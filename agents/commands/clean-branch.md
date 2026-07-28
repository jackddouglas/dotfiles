## Context

- Current branch: !`git branch --show-current`
- Working tree status: !`git status --short`
- Commit log: !`git log --oneline -30`
- Default branch: !`git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null || echo main`

## Task

Reimplement the current branch on a new branch with a clean, narrative-quality commit history suitable for reviewer comprehension.

**New branch name**: Use `$ARGUMENTS` if provided, otherwise `<source-branch>-clean`.

### Steps

1. **Identify the base**
   - Determine what the current branch forked from. Find the trunk (`main`, `master`, `develop`, or whatever `origin/HEAD` points at) and get the fork point with `git merge-base <trunk> HEAD`. Call this the **base**.
   - Note the current branch name. Call it the **source branch**.

2. **Validate the working tree**
   - Ensure there is nothing uncommitted: `git status --porcelain` must be empty.
   - If it is not, stop and report.

3. **Analyze the diff**
   - Study every change the source branch introduces: `git diff <base>...<source-branch>`.
   - Form a clear understanding of the final intended state.

4. **Create the clean branch**
   - `git switch -c <new-branch-name> <base>`

5. **Plan the commit storyline**
   - Break the implementation into self-contained logical steps.
   - Each step should reflect a stage of development -- as if writing a tutorial.
   - The sequence should tell a story: a reader stepping through the commits should understand not just *what* changed but *why*, in a natural order.

6. **Reimplement the work**
   - Recreate the changes on the clean branch, committing step by step.
   - For each logical step:
     - Apply the relevant file changes to the working tree.
     - Stage exactly what belongs to this step: `git add <paths>`, or `git add -p` when a file spans several steps.
     - Commit it: `git commit`
   - Each commit must:
     - Introduce a single coherent idea.
     - Leave the tree in a state that builds, where the project makes that practical.
     - Follow Conventional Commits: `type(scope): subject`, imperative and lowercase, under ~72 chars, with a body explaining the reasoning.

7. **Verify correctness**
   - The end state must be identical to the source branch. `git diff <source-branch> <new-branch-name>` must produce no output.
   - If it does not, fix the discrepancy before proceeding.

8. **Explain the work**
   - Run `/explain` to generate an explanation of the clean branch's changes. This helps the author quickly review and understand the narrative that was created.

### Rules

- Never add yourself as an author or contributor.
- Never include "Generated with Claude Code", "Co-Authored-By", or similar attribution lines in commit messages.
- The end state of the clean branch must be identical to the source branch.
- Do not force-push, and do not delete or move the source branch. Leave it in place so the two can be compared.
- If replaying the work onto the base produces conflicts, stop and report them rather than resolving them.
