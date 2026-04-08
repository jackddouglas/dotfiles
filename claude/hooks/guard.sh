#!/usr/bin/env bash
# Claude Code PreToolUse hook.
# Auto-allows Bash commands that are non-destructive and local.
# Dangerous or remote commands get no decision — Claude Code prompts the user.
set -euo pipefail

INPUT="$(cat)"
TOOL="$(printf '%s' "$INPUT" | jq -r '.tool_name // empty')"

# Only gate Bash; other tools are handled by the permissions allow-list
[[ "$TOOL" == "Bash" ]] || exit 0

CMD="$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty')"

# --- Destructive: require permission ---
[[ "$CMD" =~ (^|[^[:alnum:]])rm([^[:alnum:]]|$) ]] && exit 0
[[ "$CMD" =~ (^|[^[:alnum:]])sudo([^[:alnum:]]|$) ]] && exit 0
[[ "$CMD" =~ (^|[^[:alnum:]])mkfs([^[:alnum:]]|$) ]] && exit 0
[[ "$CMD" =~ (^|[^[:alnum:]])dd[[:space:]].*of= ]] && exit 0
[[ "$CMD" =~ \>[[:space:]]*/dev/[^n] ]] && exit 0
[[ "$CMD" =~ git[[:space:]]+reset[[:space:]]+--hard ]] && exit 0
[[ "$CMD" =~ git[[:space:]]+clean[[:space:]]+-[^[:space:]]*f ]] && exit 0
[[ "$CMD" =~ jj[[:space:]]+abandon ]] && exit 0

# --- Remote interaction: require permission ---
[[ "$CMD" =~ git[[:space:]]+push ]] && exit 0
[[ "$CMD" =~ git[[:space:]]+fetch ]] && exit 0
[[ "$CMD" =~ git[[:space:]]+pull ]] && exit 0
[[ "$CMD" =~ git[[:space:]]+remote[[:space:]]+(add|set-url) ]] && exit 0
[[ "$CMD" =~ jj[[:space:]]+git[[:space:]]+push ]] && exit 0
[[ "$CMD" =~ jj[[:space:]]+git[[:space:]]+fetch ]] && exit 0
[[ "$CMD" =~ curl.*\|.*(bash|sh) ]] && exit 0
[[ "$CMD" =~ wget.*\|.*(bash|sh) ]] && exit 0

# --- Safe: auto-allow ---
printf '{"decision":"allow"}\n'
