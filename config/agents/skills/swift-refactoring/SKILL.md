---
name: swift-refactoring
description: Apply Swift refactoring patterns for code quality and maintainability
---

Refactor Swift code to improve structure, reusability, and maintainability.

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
- [ ] Declare protocol conformances in separate extensions when they do not require stored properties
