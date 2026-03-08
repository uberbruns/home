# size()

The `size()` module sets absolute dimensions for `$head`, optionally aligning the result within the original space. This is used internally by `panel()` to create panel geometry, and can be used directly to constrain children to specific dimensions.

See [space model](models-space.md) and [alignment model](models-alignment.md) for related operations.

```openscad
size(space=$head, width=undef, depth=undef, height=undef, alignment=[]) children();
```

**Parameters:**
- `space` - Space to resize (default: `$head`)
- `width` - Absolute width in mm (default: `undef` keeps original)
- `depth` - Absolute depth in mm (default: `undef` keeps original)
- `height` - Absolute height in mm (default: `undef` keeps original)
- `alignment` - Alignment constant or list (default: `[]` centers on all axes)

**Alignment per axis:**
- Width: `LEFT`, `RIGHT`, or centered
- Depth: `FRONT`, `BACK`, or centered
- Height: `BOTTOM`, `TOP`, or centered

**Usage:**

Resize with centering:
```openscad
size(width=100, height=50) {
  block(); // 100mm wide, 50mm tall, centered in parent space
}
```

Align to left:
```openscad
size(width=100, alignment=LEFT) {
  block(); // 100mm wide, aligned to left edge
}
```

Multiple alignments:
```openscad
size(width=100, height=50, alignment=[LEFT, TOP]) {
  block(); // Aligned to top-left corner
}
```
