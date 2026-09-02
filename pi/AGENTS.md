# Global instructions

## Working style

- Inspect repository instructions, existing patterns, and local changes before editing.
- Keep changes narrow and preserve unrelated work.
- For feature work and debugging, isolate the smallest executable spike or vertical slice that resolves the next uncertainty. Prove it with the narrowest relevant test before broadening the change.
- Build progressively from working, tested intermediate checkpoints. Keep each increment independently reviewable; when commits are in scope, land each proven increment separately before building on it.
- Prefer focused tests while iterating. Run broader suites at meaningful integration checkpoints or when the change's blast radius requires them, not after every small edit.
- Keep durable plans and task state in ordinary repository files.
- Run servers, watchers, and other long-lived commands in named tmux windows or panes. Keep their output visible and report how to inspect or stop them.
- Spawn fresh agent contexts in named panes in the current tmux window. Target the parent `$TMUX_PANE`; never create a detached tmux session or a separate tmux window.
- Show errors and the current hypothesis before fixing non-obvious failures.
- Verify completion claims with fresh, relevant evidence after the last change; report failures and anything left unverified.
- Report uncertainty, failed checks, and assumptions directly.
- Avoid destructive Git operations.
- Keep working updates brief. Do not use emojis in code, commits, or output.

## Rust and Nix

- Prefer repository-defined formatting, linting, and test commands.
- For Rust, otherwise run `cargo fmt` and the relevant tests.
- For Nix, prefer declarative changes and format with `nix fmt` or `nixfmt`.
- Change lock files only when the requested dependency change requires it.
