### Task

Write a clear, thorough explanation of a code change and save it as a markdown file in the `notes/` directory at the project root.

### Input

{{changes}}

If the user specifies a commit, commit range, branch, or set of files, explain those changes. If no arguments are provided, explain the most recent batch of changes made in this conversation.

### Process

1. Identify the full set of changes to explain. Use `git diff`, `git log`, `git show`, or read files as needed.
2. Broadly explore the surrounding code and system context -- don't limit yourself to just the diff. Understand the before and after.
3. Write the explanation following the sections and formatting guidelines below.
4. Create the `notes/` directory if it doesn't exist.
5. Save to `notes/explain-<slug>.md` where `<slug>` is a short kebab-case descriptor of the change (e.g. `explain-add-retry-logic.md`).
6. Return the file path when done.

### Sections

- **Background**: Explain the existing system relevant to this change. Start with a broad background for readers who may be unfamiliar with this part of the codebase (note that it can be skipped by those already familiar), then narrow to the specific context directly relevant to the change.

- **Intuition**: Explain the core idea behind the change. Focus on the essence, not the full details. Use concrete examples with toy data. Use mermaid diagrams to illustrate data flow or system interactions. Pick a small number of diagram families that can be reused throughout the explanation.

- **Code**: Do a high-level walkthrough of the changes. Group and order changes in whatever way is most understandable -- not necessarily file-by-file. Reference specific files and line numbers. Explain *why*, not just *what*.

- **Verification**: Explain how the change was verified for correctness (unit tests, integration tests, type checks, etc.). Provide a step-by-step guide for how to manually QA the change.

- **Alternatives**: Describe 1-2 alternative approaches if genuinely orthogonal ways of solving the problem exist. Each alternative should include a pros and cons comparison laid out in a two-column table. If no meaningful alternatives exist, omit this section entirely.

- **Quiz**: 5 medium-difficulty multiple choice questions that test understanding of the substance of the change. Not gotchas -- the goal is to help the reader confirm they actually understood. Use `<details>` blocks for answers:

  ```
  **1. Question text?**

  - A) Option one
  - B) Option two
  - C) Option three
  - D) Option four

  <details>
  <summary>Answer</summary>

  **C) Option three** -- Explanation of why this is correct.

  - A) Why incorrect.
  - B) Why incorrect.
  - D) Why incorrect.

  </details>
  ```

### Formatting

- Write with clarity and flow. Transitions between sections should be smooth and natural, not mechanical.
- Use mermaid diagrams liberally for system diagrams, data flow, and component communication. Always include example data in diagrams.
- Use callout blocks for key concepts, definitions, and important edge cases:
  - `> [!NOTE]` for supplementary context
  - `> [!IMPORTANT]` for critical details
  - `> [!TIP]` for practical advice
- Use code blocks with language annotations when referencing code.
- Keep the explanation engaging but precise. Avoid filler.
