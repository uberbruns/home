# Alignment Model

Alignments specify panel positions and space sizing within the Headspace library. They define the six faces of a 3D space (LEFT, RIGHT, TOP, BOTTOM, FRONT, BACK) and are used by `panel()` to place panels and by `size()` to anchor resized spaces.

## Constants

Pre-defined alignment constants:

- `LEFT` - Left alignment (negative X)
- `RIGHT` - Right alignment (positive X)
- `FRONT` - Front alignment (negative Y)
- `BACK` - Back alignment (positive Y)
- `BOTTOM` - Bottom alignment (negative Z)
- `TOP` - Top alignment (positive Z)

## Constructor

### alignment_new()

Creates an alignment vector.

```openscad
alignment = alignment_new(raw_type, display_name);
```

**Parameters:**
- `raw_type` - Type string ("LEFT", "RIGHT", "TOP", "BOTTOM", "FRONT", "BACK")
- `display_name` - Human-readable name

**Returns:** Alignment vector

## Getters

### alignment_raw_type()

```openscad
type = alignment_raw_type(alignment);
```

Returns the raw type string.

### alignment_display_name()

```openscad
name = alignment_display_name(alignment);
```

Returns the human-readable name.

## Type Checking

Functions to check alignment type. Each accepts either a single alignment or a list of alignments.

### alignment_is_left()

```openscad
is_left = alignment_is_left(alignment_or_list);
```

Returns `true` if alignment is `LEFT` or if `LEFT` is in the list.

### alignment_is_right()

```openscad
is_right = alignment_is_right(alignment_or_list);
```

Returns `true` if alignment is `RIGHT` or if `RIGHT` is in the list.

### alignment_is_top()

```openscad
is_top = alignment_is_top(alignment_or_list);
```

Returns `true` if alignment is `TOP` or if `TOP` is in the list.

### alignment_is_bottom()

```openscad
is_bottom = alignment_is_bottom(alignment_or_list);
```

Returns `true` if alignment is `BOTTOM` or if `BOTTOM` is in the list.

### alignment_is_front()

```openscad
is_front = alignment_is_front(alignment_or_list);
```

Returns `true` if alignment is `FRONT` or if `FRONT` is in the list.

### alignment_is_back()

```openscad
is_back = alignment_is_back(alignment_or_list);
```

Returns `true` if alignment is `BACK` or if `BACK` is in the list.

## Usage

Single alignment check:
```openscad
if (alignment_is_left(LEFT)) {
  // true
}
```

List check:
```openscad
if (alignment_is_top([LEFT, TOP])) {
  // true - TOP is in the list
}
```
