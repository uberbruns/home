# Context Stack Transformations

These modules manage the context stack, allowing temporary modifications to naming, paint, or material that can be reverted. Use `save()` before making changes and `restore()` to revert, enabling patterns where some children use different settings than others.

See [context model](models-context.md) for context vector operations.

## update()

Replaces the current context with a new context.

```openscad
update(context) children();
```

**Parameters:**
- `context` - Context vector to replace current context

**Usage:**

```openscad
update(context_material_set(context_current(), MDF(16))) {
  block(); // Renders with MDF material
}
```

## save()

Pushes a copy of the current context onto the stack.

```openscad
save() children();
```

Use with `restore()` to temporarily modify context:

```openscad
save() {
  paint("Red") block(); // Red block
  restore() {
    block(); // Original paint restored
  }
}
```

## restore()

Pops the last context from the stack, reverting to the previous state.

```openscad
restore() children();
```

Must be paired with a preceding `save()` call.
