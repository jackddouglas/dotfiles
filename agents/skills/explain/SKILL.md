---
name: explain
description: Produce a rich HTML explanation of a code change, diff, branch, or pull request.
disable-model-invocation: true
---

# Explain

Make a rich, interactive explanation of the change named by the user, or the
current branch's diff against its base when no change is named.

It should have these sections:

- Background: Explain the existing system relevant to this change. Broadly explore surrounding code. Include deep background for beginners that experienced readers can skip, followed by narrower background directly relevant to the change.
- Intuition: Explain the essence of the change rather than every detail. Use concrete examples with toy data and figures or diagrams liberally.
- Code: Give a high-level walkthrough, grouping and ordering the changes coherently.
- Quiz: Write five medium-difficulty multiple-choice questions that test substantive understanding rather than gotchas. Clicking an answer should reveal whether it is correct and explain why.

Format:

- Output one self-contained HTML file with CSS and JavaScript. Use one long page with section headers and a table of contents rather than tabs.
- Make it responsive enough to read on a phone.
- Put it in a global location outside the repository. Start the filename with today's date in `YYYY-MM-DD-` format, for example `/tmp/2026-01-12-explanation-<slug>.html`.
- Write with the clarity and flow of Martin Kleppmann, using classic style and smooth transitions.
- Reuse a small number of diagram families where possible. Useful examples include a simplified UI and a system diagram showing data flow with concrete example data.
- Do not use ASCII diagrams. Build diagrams with HTML elements and use HTML lists for lists.
- Always use `<pre>` for code blocks. If a custom styled element is unavoidable, its CSS must use `white-space: pre` or `pre-wrap`. Before saving, verify every code block preserves whitespace.
- Use callouts for key concepts, definitions, and important edge cases.
