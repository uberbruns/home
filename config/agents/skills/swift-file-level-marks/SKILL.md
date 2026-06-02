---
name: swift-file-level-marks
description: Apply file-level MARK comments (with dash) for Swift code organization
---

Organize Swift files with file-level MARK comments to create navigable top-level sections.

Question every existing MARK comment.

### When to Add MARK Statements

- [ ] **Files with fewer than 80 lines of code probably do not need MARK statements at all** — only add them when the file complexity justifies the navigation overhead
- [ ] If MARK statements are used, apply them consistently to all file sections to create a complete outline
    - Include a `// MARK: -` before the main type declaration (except imports)
    - Once committed to using MARK statements, use them completely - partial outlines are confusing
- [ ] MARK statements require two leading lines of whitespace to separate them from preceding code
    - Exception: First MARK statement in the file may have different spacing after imports

### Naming Conventions

- [ ] Focus on semantic meaning when naming MARK statements, not technical details like access levels
    - Describe what the code does, not its visibility or implementation details
- [ ] Prefer broad, encompassing terms over specific technical terms
    - Choose terms that group related functionality conceptually
- [ ] Use broad category names, not concrete type names
    - Write `// MARK: - Model`, not `// MARK: - UserProfile`
    - The MARK label describes the role or category, not the specific type it contains
    - Exception: `// MARK: - Protocol Conformance: <protocol name>` uses the concrete protocol name because it identifies which conformance the section implements

### File-Level Sections

- [ ] Separate file-level sections with `// MARK: -` comments (with dash)
    - `// MARK: - Config`
    - `// MARK: - Model` (or other type category - see below)
    - `// MARK: - Supporting Types`
    - `// MARK: - Supporting Extensions`
    - `// MARK: - Supporting Functions`
    - `// MARK: - Supporting Protocols`
    - `// MARK: - Protocol Conformace: <protocol name>`
    - `// MARK: - Preview` (For SwiftUI files)

### Type Category Marks

- [ ] Add a generic MARK statement before the main declaration that describes the type's category
    - Choose a category name that clearly indicates the type's role in the architecture
    - Examples (other terms are possible):
        - `// MARK: - Model` for data models
        - `// MARK: - Service` for service types
        - `// MARK: - Store` for storage/persistence types
        - `// MARK: - View` for UI components
        - `// MARK: - ViewModel` for view models
        - `// MARK: - Controller` for controllers
        - `// MARK: - Manager` for management/coordination types
        - `// MARK: - Utility` for utility types
        - `// MARK: - Builder` for builder pattern types

### Verification

- [ ] Ensure all major file sections have `// MARK: -` statements
    - Main type declaration must have a category mark
    - Supporting types, extensions, and functions should have marks if present
- [ ] Ensure no legacy naming and outdated statements are still in use
