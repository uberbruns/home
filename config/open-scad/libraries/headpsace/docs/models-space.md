# Space Model

Spaces are the fundamental building block of the Headspace library, representing 3D regions with position and dimensions. The special variable `$head` tracks the current working space as it flows through the module tree. Panel modules consume space and pass the remaining interior to children.

Format: `[[x, y, z], [width, depth, height]]`

## Constructor

### space_new()

Creates a space vector.

```openscad
space = space_new(x=0, y=0, z=0, width=0, depth=0, height=0);
```

**Parameters:**
- `x`, `y`, `z` - Position coordinates (default: 0)
- `width`, `depth`, `height` - Dimensions (default: 0)

**Returns:** Space vector

**Example:**
```openscad
space = space_new(x=10, y=20, z=30, width=100, depth=200, height=300);
// Result: [[10, 20, 30], [100, 200, 300]]
```

## Getters

### space_position()

```openscad
pos = space_position(space);
```

Returns position as `[x, y, z]`.

### space_dimension()

```openscad
dim = space_dimension(space);
```

Returns dimension as `[width, depth, height]`.

### space_x(), space_y(), space_z()

```openscad
x = space_x(space);
y = space_y(space);
z = space_z(space);
```

Returns individual position coordinates.

### space_width(), space_depth(), space_height()

```openscad
width = space_width(space);
depth = space_depth(space);
height = space_height(space);
```

Returns individual dimensions.

## Usage

Direct access:
```openscad
space = space_new(x=10, width=100, height=50);
pos = space_position(space);   // [10, 0, 0]
dim = space_dimension(space);  // [100, 0, 50]
w = space_width(space);        // 100
```

Working with `$head`:
```openscad
module my_module() {
  dim = space_dimension($head);
  echo(str("Width: ", dim.x, " Depth: ", dim.y, " Height: ", dim.z));
  children();
}
```

Creating offset spaces:
```openscad
original = space_new(width=100, depth=200, height=300);
offset = space_new(
  x=space_x(original) + 10,
  y=space_y(original) + 20,
  z=space_z(original) + 30,
  width=space_width(original),
  depth=space_depth(original),
  height=space_height(original)
);
```
