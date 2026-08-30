# SCOPE

Work only within the current working directory and its subdirectories unless explicitly authorized; resolved targets determine scope.

System tools, runtimes, and installed dependencies MAY be used normally.

Access outside the project root requires explicit user authorization after stating the exact path and reason.

# GIT POLICY

Local read-only Git operations are allowed.

Before any Git operation that modifies local repository state, you MUST state the intended operation and obtain explicit user authorization. Normal project-file edits are not Git repository-state writes.

Any Git operation that interacts with a remote is STRICTLY PROHIBITED and cannot be authorized or overridden. If required, explain what the user must perform manually.

# CODING LANGUAGE

Code, identifiers, comments, documentation, logs, and internal strings MUST be in English. User-facing strings may use another language only when required by the task or existing localization conventions.

# CODING APPROACH

Prefer simple, minimal, readable, and maintainable implementations.

Before changing code, understand the relevant implementation and execution flow. Fix root causes, not symptoms.

Apply YAGNI and KISS:
- Implement actual requirements without speculative features, extensibility, configuration, or scaffolding.
- Mention substantially simpler alternatives briefly, but explicit user requirements remain authoritative.
- Reuse existing project code, conventions, helpers, and patterns before adding new ones.
- Prefer standard-library and native platform features, then existing dependencies.
- Add dependencies only when they provide a clear advantage over a small, maintainable implementation.
- Avoid unnecessary abstractions, layers, wrappers, indirection, boilerplate, and premature optimization.
- Do not abstract solely to remove minor duplication. Small duplication is preferable to a premature or incorrect abstraction.
- Prefer straightforward, boring code with explicit behavior and low cognitive complexity.
- Keep changes focused and avoid unrelated refactoring.
- Remove redundant or obsolete code only within the scope of the requested change.

Follow existing project conventions and testing infrastructure. For non-trivial behavior, add or update the smallest useful verification when appropriate.

Simplicity MUST NOT compromise correctness, security, validation, data integrity, necessary error handling, accessibility, or explicitly requested behavior.

Comments and documentation should explain non-obvious intent, constraints, or reasoning, not restate code.
