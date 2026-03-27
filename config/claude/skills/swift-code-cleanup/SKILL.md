---
name: swift-code-cleanup
description: Apply after meaningful changes to a Swift source file
---

Reorganize Swift code within files to follow a logical structure that improves readability and maintainability.

Apply each item systematically.

### Remove Obsolete Code

- [ ] Remove dead/unused code
- [ ] Inline trivial code with only one or two callers

### Refactoring

- [ ] Avoid global state
- [ ] Make constant configuration accessible at file-level with private visibility (`private enum Config { }`)
- [ ] Extract non-trivial repeated code into dedicated functions
- [ ] Extract pure supporting logic into utility functions separated from the hosting type
- [ ] Prefer small composable types with a single responsibility over larger types with unclear scope
- [ ] Type kinds: Match each abstraction to the most fitting Swift construct
    - [ ] Use classes or actors for long-lived entities whose lifecycle may be tied to other instances
        - [ ] Minimize both the number of stateful types and the amount of state each one manages
    - [ ] Use structs for data modeling and isolated functionality with no meaningful lifecycle
    - [ ] Use enums for mutually exclusive state, minimizing the number of representable states
- [ ] Pass a context instance along the call chain instead of re-fetching data already available at an earlier stage
- [ ] Prefer computed properties over cached or recomputed values when the computation is pure
- [ ] Instance methods should access state via properties, not through redundant parameters
- [ ] Restrict access levels to the minimum required visibility
- [ ] Use `let` instead of `var` for properties and variables that are never mutated

### Method Body

- [ ] Check preconditions first with `guard` statements; avoid mid-body returns
- [ ] Eliminate conditional logic when the input data is statically known and can be shaped to remove unnecessary branching
- [ ] Conditional logic should handle the expected path first
- [ ] Add one-line subheader comments describing each block's purpose
- [ ] Order operations leaf-first, building up to the final root transformation or return value
- [ ] Alphabetically order sequential accesses to properties of the same instance when order is irrelevant

### Documentation

- [ ] Developer Note (Optional)
    - [ ] Lead the file with an elevator pitch explaining the type's role in the broader project
    - [ ] Summarize the applied business rules
    - [ ] Add a glossary for domain-specific or non-obvious naming choices
    - [ ] Document meaningful or surprising workarounds
- [ ] Full documentation for public APIs and entry points only
- [ ] Single-line docs for implementation details (2-3 lines for complex methods)

### Naming

- [ ] **Consistency** - Use the same name for identical concepts throughout the code; avoid synonyms (e.g., choose `path`, `directory`, or `folder` and use consistently rather than mixing them)
- [ ] **Variables** - Specific, unabbreviated names that communicate purpose without extra context
- [ ] **Functions** - Name matches purposes and implementation in body
- [ ] **Specificity** - Prefer precise terms over generic ones; derive from symbol/function docs
- [ ] **Length** - Names should be long enough to be unambiguous and short enough to be scannable; the right name feels obvious in retrospect. Err on the side of too long rather than too short.
- [ ] **Weight** - Reserve generic verbs (`get`, `set`) for lightweight accessors; use more descriptive verbs (`discover`, `compute`, `load`) for non-trivial operations
- [ ] **Symmetry** - Similarly purposed functions may share leading or trailing terms
- [ ] **Type pattern** - `<adjective>?` + `<noun>` (e.g. `User`, `CachedTokenProvider`)
- [ ] **Function pattern** - `<verb>` + `<adjective>?` + `<noun>` + `<context>?` (e.g. `fetchActiveUsers`, `validateInputFormat`, `buildNavigationStack`)
- [ ] **State pattern** - `<gerund/noun>` + `<verb (past-tense)>` + `<context>?` (e.g. `loadingFinished`, `connectionEstablished`, `dataSynchronized`)
- [ ] **Boolean pattern** - `is` or `are` + `<adjective>?` + `<noun>` OR `<verb (3rd person present)>` + `<noun>` (e.g. `isLoading`, `isActive`, `areItemsAvailable`, `contains`, `hasItems`, `exists`)
- [ ] **Swift conventions** - Adhere to Swift API Design Guidelines and naming idioms
- [ ] **Reduce Ambiguity** - Avoid overloading terms from related technologies; reserve domain-specific terminology for its intended context (e.g., reserve `request` and `response` exclusively for HTTP operations when using an HTTP API)

### File Structure

- [ ] Order: Imports > (Developer Notes) >  Config > Type Declaration > Extensions

### Type Implementation

- [ ] Properties (stored, then computed)
- [ ] Lifecycle (`init`, `deinit`)
- [ ] Entry points (public API, protocol conformances, handlers)
- [ ] Implementation details (core logic, grouped by context/data structure operated on)
- [ ] Supporting code (helpers, utilities, formatters, validators)
- [ ] Private extensions at the end of the file
- [ ] Alphabetical order within each section for equal-level symbols

### Section Separators

- [ ] Separate logical sections with `// MARK: -` comments for top-level sections
- [ ] Use `// MARK:` (without dash) for subsections within a type
- [ ] Do not use MARK statements in small files
- [ ] If MARK statements are used, apply them consistently to all file sections
- [ ] Useful examples
    - `// MARK: - Config`
    - `// MARK: - Implementation`
    - `// MARK: Properties`
    - `// MARK: Lifecycle`
    - `// MARK: Entrypoints`
    - `// MARK: Implementation Details`
    - `// MARK: - Supporting Types`
    - `// MARK: - Supporting Extensions`
    - `// MARK: - Supporting Functions`
    - `// MARK: - Preview`

### Vertical Whitespace

- [ ] Two lines of whitespace between file-level declarations
- [ ] Two lines of whitespace before `// MARK:` statements
- [ ] One line of whitespace after `// MARK:` statements
- [ ] One line of whitespace before each property
    - [ ] No line of whitespace between properties for really simple self-documenting data types with nothing but properties in the main declaration.
