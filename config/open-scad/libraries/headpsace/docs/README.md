# Headspace Library

A parametric space construction library for OpenSCAD that enables intuitive, composable cabinet and furniture design.

## Core Concept: The Head

At the heart of Headspace is the concept of **`$head`** - a special variable that represents the current working space. Think of `$head` as a "cursor" that moves through your design, tracking the available space as you add components.

### What is a Space?

A space combines a **position** (the origin point) with **dimensions** (width, depth, height). Use `space_new()` to create spaces and accessor functions like `space_position()` and `space_dimension()` to read their properties.

See [space model](models-space.md) for available operations.

### The `$head` Variable

`$head` is a special HeadSpace variable that flows through your module tree. Each module can:
1. Read the current `$head` to know what space it's working with
2. Modify `$head` for its children, passing them a new working space

This creates a natural flow where components "consume" space and pass the remainder to the next component.

## Building a Simple Box

The most fundamental pattern in Headspace is using panel modules to construct boxes. Panel modules create a panel and automatically update `$head` to the remaining interior space.

### Basic Example

```openscad
include <lib/headspace.scad>

// Start with an initial space
$head = space_new(
  width=800,
  depth=400,
  height=600
);

// Build a box by nesting panels
// Panels use material thickness from context (default: MDF(16))
panel(BOTTOM) {
  panel(TOP) {
    panel(LEFT) {
      panel(RIGHT) {
        panel(BACK) {
          panel(FRONT);
        }
      }
    }
  }
}
```

### How It Works

Each panel module creates a panel and updates `$head` to the remaining interior space.
The **order of nesting determines the structure**. Panels added first form the outer structure, panels added later fit inside.

### Reducing Nesting

The deeply nested syntax above can be simplified in two ways:

**Single-line syntax** - OpenSCAD allows chaining modules without braces when there's only one child:
```openscad
panel(BOTTOM) panel(TOP) panel(LEFT) panel(RIGHT) panel(BACK) panel(FRONT);
```

**Alignment list** - Pass a list of alignments to create multiple nested panels in one call:
```openscad
panel([BOTTOM, TOP, LEFT, RIGHT, BACK, FRONT]);
```

Both approaches are equivalent to the nested example and produce the same result.

### Order Matters

```openscad
// Box with bottom and top that span the full width
panel(BOTTOM) {
  panel(TOP) {
    panel(LEFT) {
      panel(RIGHT);
    }
  }
}

// vs.

// Box with sides that span the full height
panel(LEFT) {
  panel(RIGHT) {
    panel(BOTTOM) {
      panel(TOP);
    }
  }
}
```

These create structurally different boxes - the first has horizontal panels that sit outside the vertical panels, the second has vertical panels that run the full height.

## Panel Module

The `panel(alignment, name)` module creates a panel at the specified alignment within `$head`:

```openscad
panel(BOTTOM)      // Panel at the bottom (z-min)
panel(TOP)         // Panel at the top (z-max)
panel(LEFT)        // Panel on the left side (x-min)
panel(RIGHT)       // Panel on the right side (x-max)
panel(BACK)        // Panel at the back (y-max)
panel(FRONT)       // Panel at the front (y-min)
```

Arguments:
- **`alignment`** - Panel position (LEFT, RIGHT, TOP, BOTTOM, FRONT, BACK)
- **`name`** - Optional name identifier (defaults to alignment name like "Bottom", "Left", etc.)

The panel module:
- Automatically uses `$head` for space
- Thickness comes from the context material (default: `MDF(16)` = 16mm MDF)
- Updates `$head` for children to the remaining interior space

## Advanced Concepts

### Hierarchical Naming with `push_name()`

The `push_name()` module creates named hierarchies for automatic component naming:

```openscad
push_name("Cabinet") {
  push_name("Left Section") {
    panel(BOTTOM);  // Named: "Cabinet/Left Section/Bottom"
    panel(TOP);     // Named: "Cabinet/Left Section/Top"
  }
}
```

Context names are automatically joined with "/" separators and prepended to panel names in the material output.

### Space Division with `columns()`, `rows()`, `lanes()`

The subdivision modules divide a space into multiple sections along a specific axis and distribute them to children:

```openscad
// Horizontal division along X axis - sections distributed round-robin to children
columns([FLEX(), FLEX(), FLEX()]) {
  drawer();  // Gets sections 0, 3, 6, ...
  drawer();  // Gets sections 1, 4, 7, ...
  drawer();  // Gets sections 2, 5, 8, ...
}

// Vertical division along Z axis with different weights
rows([FLEX(), FLEX(2), 150]) {
  drawer();  // Gets section 0 (flexible with weight 1)
  drawer();  // Gets section 1 (flexible with weight 2 - twice the space)
  drawer();  // Gets section 2 (150mm fixed height)
}

// Division along Y axis (depth)
lanes([100, FLEX(), 100]) {
  front_section();
  middle_section();
  back_section();
}
```

#### Section Types

Subdivision modules accept the following section formats:
- **Numbers** - Absolute dimensions in mm (e.g., `200` for 200mm)
- **`FLEX()`** - Flexible section with weight 1 (shares remaining space equally with other FLEX() sections)
- **`FLEX(weight)`** - Flexible section with custom weight (e.g., `FLEX(2)` gets twice as much space as `FLEX(1)`)
- **`ABS(value)`** - Explicit absolute section (equivalent to a number, but more readable)
- **`DIV()`** - Divider section using material thickness from context

#### Default Behavior: Round-Robin Distribution

When no `obj` parameters are specified on sections, subdivision modules distribute sections round-robin across children. This means:
- Child 0 gets sections 0, 3, 6, 9, ...
- Child 1 gets sections 1, 4, 7, 10, ...
- Child 2 gets sections 2, 5, 8, 11, ...

This makes it easy to repeat the same component across multiple sections.

#### Section Object Assignment with `obj`

Sections can specify which child object they belong to using the `obj` parameter:

```openscad
// Assign sections to specific children using obj property
columns([FLEX(obj=0), DIV(obj=1), FLEX(obj=0)]) {
  drawer();      // Gets sections 0 and 2 (both have obj=0)
  divider();     // Gets section 1 (has obj=1)
}

// Skip sections by not assigning them to any object
rows([FLEX(obj=0), 50, FLEX(obj=0)]) {
  shelf();  // Gets sections 0 and 2, section 1 (50mm) is unassigned
}
```

#### Repeating Sections with `repeat` and `insert`

The `repeat` parameter repeats the sections array multiple times. The `insert` parameter inserts sections between repetitions:

```openscad
// Create 5 equal shelves
rows([FLEX()], repeat=5) {
  shelf();  // Applied to all 5 sections
}

// Create 5 shelves with dividers between them
rows([FLEX(obj=0)], repeat=5, insert=[DIV(obj=1)]) {
  // Result: [FLEX, DIV, FLEX, DIV, FLEX, DIV, FLEX, DIV, FLEX]
  shelf();    // Gets sections 0, 2, 4, 6, 8 (the FLEX sections)
  divider();  // Gets sections 1, 3, 5, 7 (the DIV sections)
}

// Repeat a pattern with inserted dividers
columns([FLEX(), FLEX()], repeat=3, insert=[DIV()]) {
  // Result: [FLEX, FLEX, DIV, FLEX, FLEX, DIV, FLEX, FLEX]
  drawer();
}
```

### Working with Custom Spaces using `in()`

The `in()` module sets `$head` to a custom space:

```openscad
custom_space = space_new(x=100, y=50, width=300, depth=400, height=500);

in(custom_space) {
  // $head is now set to custom_space
  drawer("Component");
}
```

### Adjusting Spaces with `inset()` and `size()`

#### The `inset()` module - Relative adjustments

The `inset()` module shrinks or expands `$head` using relative adjustments. Positive values shrink the space inward:

```openscad
// Make a panel slightly smaller (inset by 3mm on each side)
inset(left=3, right=3, top=3, bottom=3) {
  panel(FRONT);
}

// Symmetric inset (insets left and right by 3mm each, total 6mm width reduction)
inset(width=6, depth=6) {
  panel(FRONT);
}

// Inset from specific sides
inset(front=10) {
  panel(FRONT);
}
```

#### The `size()` module - Absolute dimensions

The `size()` module sets absolute dimensions for `$head`. Use the `alignment` parameter to control positioning on each axis. If no alignment is specified for an axis, the resized space is centered:

```openscad
// Set absolute height aligned to bottom
size(height=500, alignment=BOTTOM) {
  panel(BOTTOM);
}

// Set absolute width aligned to right edge
size(width=300, alignment=RIGHT) {
  drawer("Right Drawer");
}

// Set multiple absolute dimensions with alignment
size(width=200, depth=300, alignment=[LEFT, FRONT]) {
  // Space is now 200mm wide (aligned left) and 300mm deep (aligned front)
}

// Centered by default (no alignment specified)
size(width=200, height=100) {
  // Space is centered on all axes
}
```

## Complete Example

Here's a complete example showing multiple concepts:

```openscad
include <lib/headspace.scad>

$head = space_new(
  width=2000,
  depth=400,
  height=2000
);

push_name("Shelf Unit") {
  // Create outer box
  panel([BOTTOM, LEFT, RIGHT, BACK]) {

    // Divide into 3 vertical sections
    rows([600, FLEX(), 400]) {

      // Bottom cabinet with door
      push_name("Bottom Cabinet")
        panel([BOTTOM, TOP])
          inset(left=3, right=3, top=3, bottom=3)
            panel(FRONT);

      // Open shelves in middle
      rows([FLEX()], repeat=3)
        push_name("Shelf")
          panel(BOTTOM);

      // Top cabinet
      push_name("Top Cabinet")
        panel([BOTTOM, TOP, FRONT]);
    }
  }
}
```

## Key Principles

1. **`$head` flows through your design** - Each module reads and updates it
2. **Order determines structure** - Nesting order defines how components fit together
3. **Panels consume space** - Each panel reduces the available `$head` space
4. **Subdivision distributes sections** - `columns()`, `rows()`, `lanes()` divide space and assign sections to children
5. **`obj` for section assignment** - Use `obj` parameter on sections to assign them to specific children
6. **`repeat` and `insert` for patterns** - Repeat sections with optional inserted elements
7. **Context names hierarchically** - `push_name()` builds automatic naming paths

## Special Variables Reference

- **`$head`** - The current working space (flows through module tree)
- **`$context_stack`** - Stack of context vectors for hierarchical naming, paint, and material

## Material System

Headspace uses a material model to manage panel thickness and appearance:

### Material Model
- **`MDF(thickness)`** - Creates MDF material with specified thickness (default texture: "Tan")
- Default context material: `MDF(16)` (16mm MDF)

### Setting Material
```openscad
material(MDF(18)) {
  // All panels inside use 18mm MDF
  panel(BOTTOM);
  panel(TOP);
}
```

### Paint and Texture
- **`paint(color, alpha, layer)`** - Sets paint color with layer system
- **`texture_new()`** - Creates a texture (see [texture model](models-texture.md))
- Layer 0: Base colors (used by panels)
- Layer 1+: Overlays (higher layers override lower layers)

### Context Stack Management
- **`save()`** - Pushes current context copy onto stack
- **`restore()`** - Pops context from stack
- **`update(context)`** - Replaces current context

Example:
```openscad
save() paint("Red") panel(TOP) restore() panel(BACK);
// panel(TOP) is red, panel(BACK) uses the saved context
```

## Functions Reference

- **`space_new()`** - Creates a space (see [space model](models-space.md))
- **`context_current()`** - Returns the current context from the stack

## Constants Reference

- **`FLEX(weight, obj)`** - Flexible section with optional weight (default: 1) and object assignment
- **`ABS(value, obj)`** - Absolute section with explicit value and optional object assignment
- **`DIV(obj)`** - Divider section using material thickness from context, with optional object assignment

## API Reference

### Objects

- [panel](objects-panel.md) - Panel creation with veneer support

### Transformations

- [context](transformations-context.md) - Context stack management (save, restore, update)
- [in](transformations-in.md) - Set custom `$head` space
- [inset](transformations-inset.md) - Relative space adjustments
- [material](transformations-material.md) - Set context material
- [move](transformations-move.md) - Move space position
- [name](transformations-name.md) - Hierarchical naming (name, push_name, pop_name)
- [paint](transformations-paint.md) - Set paint color
- [size](transformations-size.md) - Absolute dimensions with alignment
- [subdivide](transformations-subdivide.md) - Space division (columns, rows, lanes)
- [texture](transformations-texture.md) - Set texture

### Models

- [alignment](models-alignment.md) - Alignment constants and type checking
- [context](models-context.md) - Context vector with stack operations
- [material](models-material.md) - Material properties (thickness, texture, veneer)
- [section](models-section.md) - Section definitions (ABS, FLEX, DIV)
- [space](models-space.md) - Space vector (position and dimensions)
- [texture](models-texture.md) - Texture vector (color, alpha, layer)
