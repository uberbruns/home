---
name: swift-type-level-marks
description: Apply type-level MARK comments (without dash) for Swift code organization
---

Organize Swift types with type-level MARK comments to create navigable sections within types.

Question every existing MARK comment.

### When to Add MARK Statements

- [ ] **Files with fewer than 80 lines of code probably do not need MARK statements at all** — only add them when the file complexity justifies the navigation overhead
- [ ] If MARK statements are used, apply them consistently to all type sections
    - Once committed to using MARK statements, use them completely - partial outlines are confusing
- [ ] MARK statements require two leading lines of whitespace to separate them from preceding code

### Naming Conventions

- [ ] Focus on semantic meaning when naming MARK statements, not technical details like access levels
    - Use `// MARK: Properties` not `// MARK: Private Properties`
    - Use `// MARK: API` not `// MARK: Public API`
    - Describe what the code does, not its visibility or implementation details
- [ ] Prefer broad, encompassing terms over specific technical terms
    - Use `// MARK: Lifecycle` not `// MARK: Initialization` (Lifecycle includes init, deinit, memory pressure)
    - Use `// MARK: API` not `// MARK: Public Methods`
    - Choose terms that group related functionality conceptually

### Type-Level Sections

- [ ] Use `// MARK:` (without dash) for sections within a type
    - This distinction is crucial: dash for file-level, no dash for type-level
    - Common type-level sections:
        - `// MARK: Properties`
        - `// MARK: Lifecycle`
        - `// MARK: API`
        - `// MARK: Entrypoints`
        - `// MARK: Overrides`
        - `// MARK: Implementation Details`
        - `// MARK: Support`

### Subdividing Sections

- [ ] Subdivide long lists by adding a slash and descriptor when the section contains many related items
    - `// MARK: Implementation Details / Network`
    - `// MARK: Implementation Details / ata Processing`

### Verification

- [ ] Ensure all major type sections have `// MARK:` statements (without dash)
    - Properties, lifecycle, API, implementation details should have marks if present
- [ ] Verify type-level marks are contained within file-level sections
    - Type-level marks should only appear inside types, not at file level
- [ ] Ensure no legacy naming and outdated statements are still in use
