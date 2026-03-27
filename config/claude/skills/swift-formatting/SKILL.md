---
name: swift-formatting
description: Apply Swift formatting rules for code organization and visual structure
---

Apply Swift formatting standards for code organization and visual structure.

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

### Inline Subheading Comments

- [ ] Add one-line subheading comments to describe the purpose of each logical block in multi-step function bodies
- [ ] Place subheading comments on the line immediately before the block the comment describes
- [ ] Use clear, concise descriptions in present tense without personal pronouns
- [ ] Keep comments short (typically 2-6 words)
- [ ] Examples:
    - `// Validate input parameters`
    - `// Configure network request`
    - `// Transform response data`
    - `// Update UI state`
    - `// Handle error cases`

### Vertical Whitespace

- [ ] Two lines of whitespace between file-level declarations
- [ ] Two lines of whitespace before `// MARK:` statements
- [ ] One line of whitespace after `// MARK:` statements
- [ ] One line of whitespace before each property
    - [ ] No line of whitespace between properties for really simple self-documenting data types with nothing but properties in the main declaration.
