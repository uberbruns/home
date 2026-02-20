Reorganize code within files to follow a logical structure that improves readability and maintainability.

### Remove obsolete code

1. **Remove Obsolete** - Remove obsolete code
2. **Inline Trivial** - Inline trivial code that only has one or two callers without doing anything smart


### Function Body

1. **Comments** - Function bodies should contain one-line subheader-like comments that didactically describe what the next block(s) of code will be about. These comments serve as internal documentation to guide readers through the logic flow.

2. **Construction Flow** - Function bodies should create and transform content by performing deep leaf operations and constructions first and then systematically walk the tree until the final root transformation or creation is reached and the final action is executed or value is returned.

3. Lead a function by checking preconditions first. Avoid return in the middle of a function body.


### Function Docs

1. Only public functions or entry points should get a full documentation.
2. Implementation detail functions only get a single line documentation. Only complec function get 2-3.


### Naming

1. **Variables** - Avoid overly generic variable names and needless abbreviations. Names should clearly communicate purpose and meaning without requiring additional context.
2. **Functions** - Ensure that function name and purpose match and are easy to grasp.
3. **Consistency** - Ensure that through the flow of functions variable names stay consistent or stay related if they describe the same concept. Pick a name and stick with it. Avoid synonyms.
4. **Symmetry** - Create symmetry between similarly named functions and symbols. If possible, make the names of similarly named functions and symbols start with the same terms.
5. **Function Pattern** - For functions prefer the pattern <verb> + (optional <clarifying adjective>) + <noun> + (optional <specific context>)
6. **State Pattern** - For state constants and enums prefer the pattern <gerund/noun> + <verb (past-tense)> + (optional <specific context>)
7. **Specificity** - Avoid overly generic terms when more specific terms are available. Use the symbol or function doc as reference for terms that make a symbol or function unique.



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
3. **Implementation Details** - Core logic, business rules, algorithms. Create sections for similar functions that work in a similar context or on similar data structures.
4. **Supporting Code** - Helper functions, utilities, formatters, validators
5. **Alphabetical Order** - Within each section, use alphabetical order for functions and symbols that are on an equal level.

### Section Separators

Logically related symbols and functions should be separated from other sections using ASCII art comment separators matching the language conventions:
