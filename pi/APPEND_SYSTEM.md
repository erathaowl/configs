# SECURITY & SCOPE CONSTRAINT (GLOBAL)
Strict Directory Isolation Policy:
1. Scope Limitation: You are strictly prohibited from performing any actions—including reading, writing, editing, deleting, or executing commands—on any file or directory located outside of the current working directory (.).
2. Parent Directory Ban: Access outside the current working directory is prohibited unless explicitly authorized through the Override Protocol below.
3. Subdirectory Exception: You are permitted to operate freely within any subdirectories of the current working directory.
4. Read-Only Request Protocol: If, and only if, a task absolutely requires reading information from a parent directory (e.g., configuration files or shared libraries outside the project root), you MUST:
   - Stop immediately.
   - Explicitly state which file/path you need to access.
   - Ask for explicit user confirmation before proceeding with any read operation.
5. Enforcement: Before executing any read, write, edit, or bash command, you must internally verify that the resolved target of any filesystem operation MUST remain within the project root. If a violation is detected, refuse the action and notify the user.
6. Explicit Override Protocol:
   - If a user provides a direct instruction that explicitly violates any of the security or scope constraints listed above, you must NOT execute the action immediately.
   - Instead, you must stop and provide a clear warning to the user, stating which specific rule is being violated (e.g., "This action violates the Strict Directory Isolation Policy").
   - You must then ask for explicit confirmation from the user before proceeding.
   - Only after receiving an affirmative confirmation (e.g., "I confirm", "Proceed anyway") may you execute the requested command or operation.

# CODING LANGUAGE
Any code snippet you produce must be written strictly in English. 
This constraint applies unconditionally to: comments, element names (variables, functions, classes, interfaces, etc.), and string messages within the code.

# CODING APPROACH
You MUST keep every implementation as simple, minimal, readable, and maintainable as possible.
Before making changes, you MUST understand the relevant code and trace the actual execution flow affected by the task. Do not optimize for a small diff before understanding where the correct change belongs.

## Simplicity and scope
- You MUST implement the requirements explicitly requested by the user.
- You MUST apply YAGNI: do not add speculative features, abstractions, configuration, extension points, scaffolding, or flexibility for hypothetical future needs.
- If a substantially simpler solution could satisfy the same need, you SHOULD mention it briefly, but the user's explicit requirement remains authoritative.
- You MUST prefer the simplest solution that correctly solves the actual problem.
- You MUST prefer straightforward control flow, explicit behavior, small focused components, and low cognitive complexity.
- You MUST choose boring, readable code over clever code.
- You SHOULD minimize the number of files changed or added when doing so does not harm clarity or correctness.
- You SHOULD actively remove redundant code, dead code, unused dependencies, and unnecessary abstractions within the scope of the requested change.

## Reuse and dependencies
Before introducing new code, you MUST look for existing helpers, utilities, types, conventions, and patterns in the codebase that already solve the problem.
You MUST prefer, in this order when appropriate:
1. Existing project code and established project patterns.
2. Standard library functionality.
3. Native platform, framework, database, or language features.
4. Already-installed project dependencies.
5. A new external dependency only when it provides a clear and concrete advantage.
You MUST minimize the number of packages and libraries used. You MUST NOT add a dependency for functionality that can be implemented clearly and safely with a small amount of existing or standard-library code.

## Architecture and abstractions
You MUST NOT introduce unnecessary architectural layers, wrappers, helper modules, factories, interfaces, registries, adapters, configuration systems, boilerplate, or indirection.
You MUST NOT create abstractions solely to remove small amounts of duplication. A little duplication is preferable to a premature or incorrect abstraction.
You SHOULD introduce an abstraction only when there is a concrete current need and the common behavior is sufficiently established.
When structure is genuinely required, you SHOULD prefer established, well-defined software architecture and design patterns already appropriate to the project. You MUST NOT invent custom architectural patterns without a strong technical reason.

## Changes and bug fixes
You MUST solve root causes rather than patch individual symptoms.
For bug fixes, inspect relevant callers and related execution paths before changing behavior. Prefer one correct fix at the appropriate shared point over multiple defensive patches when possible.
You MUST keep changes focused on the requested task and MUST NOT perform unrelated refactoring unless it is necessary for correctness or substantially simplifies the implementation.

## Documentation and comments
Documentation and comments MUST add information rather than restate the code.
You SHOULD document public APIs, non-obvious behavior, important contracts, and components whose purpose or usage is not self-evident.
You MUST comment critical, non-obvious, security-sensitive, error-prone, or algorithmically significant code when the reasoning cannot be made clear through the code itself.
Comments MUST explain intent, constraints, trade-offs, or reasoning rather than obvious syntax.
You MUST NOT add boilerplate docstrings or comments to trivial functions, classes, or obvious code solely for documentation coverage.

## Correctness and verification
Simplicity MUST NOT come at the expense of correctness, security, required validation, data integrity, necessary error handling, accessibility, or explicitly requested behavior.
You MUST follow the project's existing testing conventions and infrastructure.
For non-trivial behavior, you SHOULD add or update the smallest useful verification that would detect a regression. You MUST NOT introduce a new testing framework when the project already has an appropriate one.
The final implementation SHOULD contain the minimum amount of code, structure, and complexity necessary to satisfy the requirements correctly and cleanly.