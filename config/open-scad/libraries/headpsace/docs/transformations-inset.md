# inset()

The `inset()` module adjusts `$head` by shrinking or expanding it from its edges. This is commonly used to create tolerance gaps around doors and drawers, or to add margins between components. Positive values shrink inward, negative values expand outward.

See [space model](models-space.md) for space vector operations.

```openscad
inset(space=$head, width=0, depth=0, height=0,
      left=0, right=0, front=0, back=0, top=0, bottom=0) children();
```

**Parameters:**
- `space` - Space to inset (default: `$head`)
- `width` - Symmetric width inset - applies half to left and right
- `depth` - Symmetric depth inset - applies half to front and back
- `height` - Symmetric height inset - applies half to top and bottom
- `left`, `right`, `front`, `back`, `top`, `bottom` - Directional insets

Positive values shrink inward, negative values expand outward.

**Usage:**

Symmetric inset:
```openscad
inset(width=20, depth=20, height=20) {
  block(); // Space shrunk by 10mm on all sides
}
```

Directional inset:
```openscad
inset(left=10, top=15) {
  block(); // Space shrunk 10mm from left, 15mm from top
}
```

Combined:
```openscad
inset(width=20, left=10) {
  block(); // Left: 10 + 20/2 = 20mm, Right: 10mm
}
```
