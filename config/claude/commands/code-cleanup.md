Reorganize code within files to follow a logical structure that improves readability and maintainability.

Apply each item systematically.

### Remove Obsolete Code

- [ ] Remove dead/unused code
- [ ] Inline trivial code with only one or two callers

### Refactoring

- [ ] Avoid global state
- [ ] Make constant configuration accessible on file-level with the minimum required visibility
- [ ] Extract non-trivial repeated code into dedicated functions
- [ ] Extract pure supporting logic into utility functions separated from the hosting object
- [ ] Prefer small composable objects with a single responsibility over larger objects with unclear scope
- [ ] Object kinds: Match each abstraction to the most fitting language construct
    - [ ] Use stateful objects for long-lived entities whose lifecycle may be tied to other objects
        - [ ] Minimize both the number of stateful objects and the amount of state each one manages
    - [ ] Use stateless objects for data modeling and isolated functionality with no meaningful lifecycle
    - [ ] Use enumerations for mutually exclusive state, minimizing the number of representable states
- [ ] Eliminate conditional logic when the input data is statically known and can be shaped to remove unnecessary branching
- [ ] Pass a context object along the call chain instead of re-fetching data already available at an earlier stage
- [ ] Prefer computed properties over cached or recomputed values when the computation is pure
- [ ] Object methods should access state via properties, not through redundant arguments
- [ ] Restrict access levels to the minimum required visibility

### Function Body

- [ ] Check preconditions first; avoid mid-body returns
- [ ] Add one-line subheader comments describing each block's purpose
- [ ] Order operations leaf-first, building up to the final root transformation or return value
- [ ] Alphabetically order sequential accesses to properties of the same object when order is irrelevant

### Docs

- [ ] Header
    - [ ] Lead the file with an elevator pitch explaining the function's role in the broader project
    - [ ] (Optional) Summarize the applied business rules
    - [ ] (Optional) Add a glossary for domain-specific or non-obvious naming choices
    - [ ] (Optional) Document meaningful or surprising workarounds
- [ ] Full documentation for public functions and entry points only
- [ ] Single-line docs for implementation details (2-3 lines for complex functions)

### Naming

- [ ] **Consistency** - Same concept uses same name (or name variant) across function flow; avoid synonyms
- [ ] **Variables** - Specific, unabbreviated names that communicate purpose without extra context
- [ ] **Functions** - Name and purpose match and are easy to grasp
- [ ] **Specificity** - Prefer precise terms over generic ones; derive from symbol/function docs
- [ ] **Weight** - Reserve generic verbs (`get`, `set`) for lightweight accessors; use more descriptive verbs (`discover`, `compute`, `load`) for non-trivial operations
- [ ] **Symmetry** - Similarly purposed functions may share leading terms
- [ ] **Object pattern** - `<adjective>?` + `<noun>` (e.g. `User`, `CachedTokenProvider`)
- [ ] **Function pattern** - `<verb>` + `<adjective>?` + `<noun>` + `<context>?` (e.g. `fetchActiveUsers`, `validateInputFormat`, `buildNavigationStack`)
- [ ] **State pattern** - `<gerund/noun>` + `<verb (past-tense)>` + `<context>?` (e.g. `loadingFinished`, `connectionEstablished`, `dataSynchronized`)
- [ ] **Boolean pattern** - `is` or `are` + `<adjective>?` + `<noun>` OR `<verb (3rd person present)>` + `<noun>` (e.g. `isLoading`, `isActive`, `areItemsAvailable`, `contains`, `hasItems`, `exists`)
- [ ] **Language conventions** - Adhere to language naming standards and idioms

### File Structure

- [ ] Order: Imports > Configuration > Implementation > Exports/Main Invocation

### Implementation

- [ ] Properties
- [ ] Lifecycle (init, setup, teardown)
- [ ] Entry points (public API, handlers)
- [ ] Implementation details (core logic, grouped by context/data structure operated on)
- [ ] Supporting code (helpers, utilities, formatters, validators)
- [ ] Alphabetical order within each section for equal-level symbols

### Section Separators

- [ ] Separate logical sections with markers or comment dividers matching language conventions
