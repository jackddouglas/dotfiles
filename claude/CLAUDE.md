# Global Instructions

## Environment

- macOS (Apple Silicon), nix-darwin + home-manager
- Shell: fish
- Editor: neovim
- VCS: jj (colocated with git)
- Terminal: ghostty
- Secrets: 1Password CLI (`op`)
- Package manager: nix (prefer nix-idiomatic solutions)

## Voice

Write clearly and concisely. The goal is prose a sharp human would write.

- Lead with the answer. Cut preamble, throat-clearing, and restating the question.
- Plain words over jargon. Define a term only if it carries weight.
- Concrete and specific beats vague and hedged. Say what is true, not what is safe.
- No filler praise ("Great question"), no hedging boilerplate, no padding to seem thorough.
- Vary sentence length. Short sentences land. Don't pad them into uniform mush.
- Drop the AI tells: "delve", "leverage", "boasts", "it's worth noting", "in today's world", "—and that's a good thing", rule-of-three everything, and tidy bow-tie conclusions.
- Match length to the question. A one-line answer is a complete answer.

## Preferences

- No emojis in code, commits, or output
- Use `nix fmt` / `nixfmt` for nix files
- Keep things minimal and explicit

## VCS

Repos are jj/git colocated; prefer jj end-to-end. Fall back to git only for what jj doesn't cover (e.g. `gh` for PRs).

- Status / diff / history: `jj st`, `jj diff`, `jj log`, `jj show <rev>`
- Describe current change: `jj describe -m "..."`
- New change on top: `jj new`
- Describe + start new in one step: `jj commit -m "..."`
- Squash working-copy change into parent: `jj squash`
- Bookmarks (= git branches): `jj bookmark create <name> -r <rev>`, `jj bookmark set <name> -r <rev>`, `jj bookmark delete <name>`, `jj bookmark list`
- Sync with remote: `jj git fetch`, `jj git push` (all tracked bookmarks) or `jj git push -b <name>`
- Rebase: `jj rebase -d <dest>`

Gotchas:

- No staging area — the working copy is always part of the current change. Don't `git add`.
- After `jj commit`, you're on a fresh empty change; subsequent edits land there, not in the commit you just made.
- Bookmarks don't auto-follow new commits; use `jj bookmark set` to move them.
- For PRs: create/move the bookmark with jj, push with `jj git push`, then use `gh pr create`.
- Don't run destructive ops (`jj abandon`, `jj restore`, `jj op restore`, force pushes) without asking.

## Commit messages

- Use [Conventional Commits](https://www.conventionalcommits.org/): `type(scope): subject`
- Common types: `feat`, `fix`, `chore`, `refactor`, `docs`, `test`, `perf`, `build`, `ci`, `style`
- Scope is the crate, package, or area of work (infer from git history when unclear)
- Subject in imperative mood, lowercase, no trailing period
- Keep the subject under ~72 characters; put detail in the body

## Formatting

- Inline code uses single backticks: `foo`
- Block code uses triple backticks with a language tag when applicable:

  ```fish
  echo hello
  ```
