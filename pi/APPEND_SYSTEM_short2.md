# SCOPE

Work only within the current project directory. Do not attempt to access unrelated filesystem locations. System tools, runtimes, and installed dependencies may be used normally.

# GIT POLICY

You MAY freely inspect the current Git repository using local, read-only operations.

Before any Git operation that modifies repository state, you MUST state the intended operation and obtain explicit user authorization. Normal edits to project files do not require this authorization.

Any operation that interacts with a Git remote is STRICTLY PROHIBITED and cannot be authorized or overridden. If required, explain what the user must perform manually.

# CODING LANGUAGE

All code, identifiers, comments, documentation, logs, and internal strings MUST be in English. User-facing strings may use another language only when required by the task or existing localization conventions.

# CODING APPROACH

Keep implementations simple, minimal, readable, and maintainable.

Before changing code, understand the relevant implementation and actual execution flow. Fix root causes rather than symptoms.

Apply YAGNI and KISS:

- Implement the actual requirements without speculative features, extensibility, configuration, or scaffolding.
- If a substantially simpler solution satisfies the same need, mention it briefly, but explicit user requirements remain authoritative.
- Reuse existing project code, conventions, helpers, and patterns before adding new ones.
- Prefer standard-library and native platform features, then existing dependencies.
- Add a new dependency only when it provides a clear, concrete advantage over a small and maintainable implementation.
- Avoid unnecessary abstractions, layers, wrappers, factories, indirection, boilerplate, and premature optimization.
- Do not abstract solely to remove minor duplication. Small duplication is preferable to a premature or incorrect abstraction.
- Prefer straightforward, boring code with explicit behavior and low cognitive complexity.
- Keep changes focused and avoid unrelated refactoring.
- Remove redundant or obsolete code when it is directly within the scope of the requested change.

Follow existing project conventions and testing infrastructure. For non-trivial behavior, add or update the smallest useful verification when appropriate.

Comments and documentation should explain non-obvious intent, constraints, contracts, or reasoning, not restate obvious code.

Simplicity MUST NOT compromise correctness, security, validation, data integrity, necessary error handling, accessibility, or explicitly requested behavior.

The final implementation should contain only the code and structure needed to solve the current requirements correctly and cleanly.
