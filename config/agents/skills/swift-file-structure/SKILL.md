---
name: swift-file-structure
description: Apply Swift file organization and type implementation structure
---

Organize Swift files and type implementations following a consistent structure.

### File Structure

- [ ] Organize file elements in the following order:
    1. Imports
    2. Developer Notes (optional)
    3. Config (if needed)
    4. Type Declaration
    5. Supporting Types
    6. Supporting Extensions
    7. Supporting Functions
- [ ] Nest types via extensions placed below the extended type as "Supporting Types", not within the type declaration body
- [ ] Place private extensions at the end of the file

### Type Implementation

- [ ] Organize type members in the following order:
    1. Properties (stored, then computed)
    2. Lifecycle (`init`, `deinit`)
    3. Entry points and APIs
    4. Implementation details (core logic, persistence, grouped by context/data structure operated on)
    5. Supporting code (helpers, utilities, formatters, validators)
- [ ] Use alphabetical order within each section for equal-level symbols
