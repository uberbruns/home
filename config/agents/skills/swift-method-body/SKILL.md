---
name: swift-method-body
description: Apply Swift method body structure and organization patterns
---

Structure method bodies for clarity and maintainability.

### Method Body

- [ ] Check preconditions first with `guard` statements; avoid mid-body returns
- [ ] Eliminate conditional logic when the input data is statically known and can be shaped to remove unnecessary branching
- [ ] Conditional logic should handle the expected path first
- [ ] Add one-line subheader comments describing each block's purpose
- [ ] Order operations leaf-first, building up to the final root transformation or return value
- [ ] Alphabetically order sequential accesses to properties of the same instance when order is irrelevant
