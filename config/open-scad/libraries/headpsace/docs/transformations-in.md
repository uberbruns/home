# in()

The `in()` module sets `$head` to a specified space, establishing the working region for children. This is typically used at the top level to define the initial space for a design, or to render children in a specific location independent of the current `$head`.

See [space model](models-space.md) for space vector operations.

```openscad
in(space) children();
```

**Parameters:**
- `space` - Space vector to set as `$head`

**Usage:**

```openscad
in(space_new(x=10, y=20, z=30, width=100, depth=200, height=300)) {
  block(); // Renders in explicitly defined space
}
```

Useful for rendering children in a space independent of the parent's `$head`.
