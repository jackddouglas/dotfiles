# Global instructions

## Working style

- Inspect repository instructions, existing patterns, and local changes before editing.
- Keep changes narrow and preserve unrelated work.
- Keep durable plans and task state in ordinary repository files.
- Show errors and the current hypothesis before fixing non-obvious failures.
- Report uncertainty, failed checks, and assumptions directly.
- Avoid destructive Git operations.
- Keep working updates brief. Do not use emojis in code, commits, or output.

## Rust and Nix

- Prefer repository-defined formatting, linting, and test commands.
- For Rust, otherwise run `cargo fmt` and the relevant tests.
- For Nix, prefer declarative changes and format with `nix fmt` or `nixfmt`.
- Change lock files only when the requested dependency change requires it.
