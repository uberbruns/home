# move()

The `move()` module shifts the position of `$head` without changing its dimensions. This allows offsetting children from their natural position, useful for creating visual gaps or adjusting component placement.

See [space model](models-space.md) for space vector operations.

```openscad
move(space=$head, left=0, right=0, front=0, back=0, bottom=0, top=0) children();
```

**Parameters:**
- `space` - Space to move (default: `$head`)
- `left` - Move left (negative X)
- `right` - Move right (positive X)
- `front` - Move forward (negative Y)
- `back` - Move backward (positive Y)
- `bottom` - Move down (negative Z)
- `top` - Move up (positive Z)

Positive values move in the named direction.

**Usage:**

```openscad
move(right=50, top=100) {
  block(); // Position shifted +50 in X, +100 in Z
}
```

Conflicting directions net out:
```openscad
move(left=30, right=50) {
  block(); // Net movement: +20 in X
}
```
