# panel()

The panel module is the primary building block for constructing cabinets and furniture in the Headspace library. It creates a panel at a specified face of the current space, reduces `$head` by the panel thickness, and passes the remaining interior to children. Multiple panels can be specified as a list for concise box construction.

See [alignment model](models-alignment.md), [material model](models-material.md), and [space model](models-space.md) for related operations.

```openscad
panel(alignment, name, material) children();
```

**Parameters:**
- `alignment` - Single alignment constant or list of alignments (LEFT, RIGHT, TOP, BOTTOM, FRONT, BACK)
- `name` - Name identifier (default: derived from alignment display name, only valid for single alignment)
- `material` - Material vector (default: `context_material(context_current())`)

Each panel occupies one face of `$head` with thickness from the material. The remaining interior space is passed to children via `$head`.

## Single Alignment

Creates a single panel at the specified face.

```openscad
panel(BOTTOM) {
  // $head is now the interior space after the bottom panel
}
```

Custom name:
```openscad
panel(LEFT, name="Side") {
  // Panel named "Side" instead of "Left"
}
```

Override material:
```openscad
panel(TOP, material=MDF(18)) {
  // Top panel uses 18mm MDF instead of context material
}
```

## List of Alignments

When given a list, panels are nested from first to last. This creates multiple panels in a single call.

```openscad
panel([BOTTOM, TOP, LEFT, RIGHT, BACK, FRONT]);
// Equivalent to:
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

The `name` parameter is ignored when using a list. Each panel uses its alignment display name.

## Veneer Structure

Panels automatically include veneer layers if the material defines veneer properties:

- Front veneer (outer face): `material_veneer_front(material)` thickness
- Base material: Remaining thickness
- Back veneer (inner face): `material_veneer_back(material)` thickness

Veneer texture from `material_veneer_texture(material)` is applied to veneer layers. Zero-thickness veneers are automatically omitted.

## Usage

Basic box:
```openscad
$head = space_new(width=800, depth=400, height=600);
panel([BOTTOM, TOP, LEFT, RIGHT, BACK, FRONT]);
```

Nested panels with children:
```openscad
panel(BOTTOM) {
  panel(TOP) {
    panel(LEFT) {
      panel(RIGHT) {
        // Create 3 compartments, bottom one shares outer bottom panel
        rows([FLEX()], repeat=3, insert=[FLEX(obj=0)]) {
          panel(BOTTOM); // Creates bottom panels for middle and top compartments only
        }
      }
    }
  }
}
```

Single-line nesting syntax:
```openscad
panel(BOTTOM) panel(TOP) panel(LEFT) panel(RIGHT) panel(BACK) panel(FRONT);
```

Veneer example:
```openscad
plywood = material_new(
  "Plywood",
  18,
  texture=texture_new("BurlyWood"),
  veneer_texture=texture_new("SaddleBrown"),
  veneer_front=0.6,
  veneer_back=0.6
);

material(plywood) {
  panel(BOTTOM); // 18mm panel with 0.6mm veneer on both faces
}
```

Structural order matters:
```openscad
// Bottom/top span full width
panel([BOTTOM, TOP, LEFT, RIGHT]);

// vs. left/right span full height
panel([LEFT, RIGHT, BOTTOM, TOP]);
```
