# SECURITY & SCOPE CONSTRAINT (GLOBAL)
Strict Directory Isolation Policy:
1. Scope Limitation: You are strictly prohibited from performing any actions—including reading, writing, editing, deleting, or executing commands—on any file or directory located outside of the current working directory (.).
2. Parent Directory Ban: Access to parent directories (e.g., using ../, .., or absolute paths pointing outside the project root) is strictly forbidden under all circumstances.
3. Subdirectory Exception: You are permitted to operate freely within any subdirectories of the current working directory.
4. Read-Only Request Protocol: If, and only if, a task absolutely requires reading information from a parent directory (e.g., configuration files or shared libraries outside the project root), you MUST:
   - Stop immediately.
   - Explicitly state which file/path you need to access.
   - Ask for explicit user confirmation before proceeding with any read operation.
5. Enforcement: Before executing any read, write, edit, or bash command, you must internally verify that the target path is relative and does not escape the current directory. If a violation is detected, refuse the action and notify the user.
6. Explicit Override Protocol:
   - If a user provides a direct instruction that explicitly violates any of the security or scope constraints listed above, you must NOT execute the action immediately.
   - Instead, you must stop and provide a clear warning to the user, stating which specific rule is being violated (e.g., "This action violates the Strict Directory Isolation Policy").
   - You must then ask for explicit confirmation from the user before proceeding.
   - Only after receiving an affirmative confirmation (e.g., "I confirm", "Proceed anyway") may you execute the requested command or operation.

# CODING LANGUAGE
1. Any code snippet you produce must be written strictly in English. 
2. This constraint applies unconditionally to: comments, element names (variables, functions, classes, interfaces, etc.), and string messages within the code.

# CODING APPROACH
You MUST keep every implementation as simple, minimal, readable, and maintainable as possible.  You MUST NOT introduce unnecessary abstractions, architectural layers, wrappers, helper modules, boilerplate, indirection, configuration, dependencies, frameworks, or speculative extensibility. 
You MUST minimize the number of packages and libraries used, and MUST introduce an external dependency only when it is clearly necessary and provides a concrete advantage over the standard library or existing project dependencies. 
You SHOULD prefer established, well-defined software architecture and design patterns when structure is genuinely required, and MUST avoid inventing custom architectural patterns without a strong technical reason. 
You MUST prefer straightforward control flow, explicit behavior, small focused components, and low cognitive complexity. 
You MUST choose simple code over clever code and MUST introduce additional complexity only when required by the actual problem. 
Every function and class MUST include concise documentation explaining its purpose, responsibilities, inputs, outputs, and relevant side effects. 
You MUST comment every critical, non-obvious, security-sensitive, error-prone, or algorithmically significant section of code. 
Comments MUST explain intent and reasoning rather than restating obvious syntax. 
You SHOULD actively remove redundant code, unused dependencies, unnecessary generalization, premature optimization, and abstractions that do not provide immediate value. 
The final implementation SHOULD contain the minimum amount of code and structure necessary to solve the requirements correctly and cleanly.
