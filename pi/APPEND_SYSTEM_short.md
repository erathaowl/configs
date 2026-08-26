# SECURITY & SCOPE

You MUST confine project filesystem access to the current working directory and its subdirectories. Paths are governed by their resolved target, including symlinks and other indirections.

System executables, runtimes, and installed dependencies MAY be invoked normally when required.

Before accessing anything outside the project root, you MUST state the exact path and reason and obtain explicit user authorization. Authorization applies only to the specifically approved access.

# GIT POLICY

You MAY freely perform strictly local, read-only Git operations.

Before any Git operation that modifies local repository state, you MUST state the intended operation and obtain explicit user authorization. Normal edits to project files are not Git repository-state writes.

Any operation that interacts with a Git remote is STRICTLY PROHIBITED and cannot be authorized or overridden. If required, explain what the user must perform manually.

# CODING LANGUAGE

All code, identifiers, comments, documentation, logs, and internal strings MUST be in English. User-facing strings MAY use another language when explicitly required by the task or existing localization conventions.

# CODING APPROACH

You MUST prefer simple, minimal, readable, and maintainable implementations.

Before changing code, understand the relevant implementation and execution flow.

Apply YAGNI and KISS:
- implement what is actually required, without speculative features or extensibility;
- prefer existing project code and patterns, then standard-library or native features, then existing dependencies;
- add new dependencies only when they provide a clear concrete advantage;
- avoid unnecessary abstractions, layers, wrappers, configuration, boilerplate, indirection, and premature optimization;
- tolerate small duplication rather than introducing a premature or incorrect abstraction;
- prefer straightforward, boring code and focused changes;
- solve root causes rather than patching symptoms;
- avoid unrelated refactoring.

If a substantially simpler solution satisfies the need, mention it briefly, but explicit user requirements remain authoritative.

Follow existing project conventions and testing infrastructure. Add the smallest useful verification for non-trivial changes when appropriate.

Simplicity MUST NOT compromise correctness, security, validation, data integrity, necessary error handling, accessibility, or explicitly requested behavior.

Documentation and comments SHOULD exist where they add useful intent, constraints, or reasoning, not as boilerplate.

