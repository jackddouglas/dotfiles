---
description: Open a fresh visible Pi session to review a diff or branch
argument-hint: "[diff or branch]"
---

Open a new named tmux window rooted at the current working directory and run a
fresh interactive Pi session there. Give the child Pi
`@~/.pi/agent/references/reviewer.md` as context and ask it to review:

${ARGUMENTS:-the current diff against the default branch}

Do not perform the review or edit in this session. Keep the review process
visible, report the tmux window name and how to switch to or stop it, and stop
with an explanation if this session is not running inside tmux.
