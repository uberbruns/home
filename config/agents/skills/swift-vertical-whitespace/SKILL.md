---
name: swift-vertical-whitespace
description: Apply vertical whitespace rules for Swift code readability
---

Apply consistent vertical whitespace for improved Swift code readability.

### Vertical Whitespace

- [ ] No whitespace between import statements
- [ ] All `@` attributes attached to types, functions, and properties stand on their own line
    - `@Published`, `@State`, `@Binding`, `@MainActor`, `@Observable`, etc.
    - Exception: Parameter attributes like `@escaping`, `@Sendable` remain inline
- [ ] Two lines of whitespace between file-level declarations
- [ ] Two lines of whitespace before `// MARK:` statements
- [ ] One line of whitespace after `// MARK:` statements
- [ ] One line of whitespace before each property
    - [ ] No line of whitespace between properties for really simple self-documenting data types with nothing but properties (not even a simple init function) in the main declaration.
    - [ ] Yes, even the first property.
