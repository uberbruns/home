Reorganize code within files to follow a logical structure that improves readability and maintainability.

### Overall File Structure

Files are organized in this order:

1. **Imports/Requirements** - All external dependencies
2. **Configuration** - Constants, types, enums, configuration objects
3. **Source Code** - Functions, classes, methods (see ordering below)
4. **Exports/Main Invocation** - Module exports or main entry point execution

### Source Code Ordering

Within the source code section, organize in this priority:

1. **Lifecycle Code** - Initialization, setup, teardown, constructors, destructors
2. **Entry Points** - Main functions, public API, command handlers
3. **Implementation Details** - Core logic, business rules, algorithms
4. **Supporting Code** - Helper functions, utilities, formatters, validators

### Section Separators

Logically related symbols and functions should be separated from other sections using ASCII art comment separators matching the language conventions:


### Function Body Comments

Function bodies should contain one-line subheader-like comments that didactically describe what the next block(s) of code will be about. These comments serve as internal documentation to guide readers through the logic flow.

### Naming

- Variables: Avoid overly generic variable names and needless abbreviations. Names should clearly communicate purpose and meaning without requiring additional context.
- Functions: Ensure that function name and purpose match and are easy to grasp.
- Ensure that through the flow of functions variable names stay consistent and or stay related if they describe the same concept. Pick a name and stick with it. Avoid synonyms.

