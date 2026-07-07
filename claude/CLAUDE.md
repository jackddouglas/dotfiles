# Global Instructions

## Environment

- macOS (Apple Silicon), nix-darwin + home-manager
- Shell: fish
- Editor: neovim
- VCS: git
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

Use git end-to-end. Use `gh` for GitHub operations such as creating PRs.

- Status / diff / history: `git status`, `git diff`, `git log`, `git show <rev>`
- Stage changes: `git add <path>` or `git add -p`
- Commit staged changes: `git commit -m "..."`
- Branches: `git switch -c <name>`, `git switch <name>`, `git branch -d <name>`, `git branch --list`
- Sync with remote: `git fetch`, `git pull --rebase`, `git push` or `git push -u origin <name>`
- Rebase: `git rebase <dest>`

Gotchas:

- Review staged changes with `git diff --cached` before committing.
- Don't stage unrelated changes; prefer explicit paths or `git add -p` over `git add .`.
- For PRs: create a branch, push it with `git push -u origin <name>`, then use `gh pr create`.
- Don't run destructive ops (`git reset --hard`, `git clean`, forced branch deletion, force pushes) without asking.

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
