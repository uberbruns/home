# Space Subdivision

The subdivision modules (`columns()`, `rows()`, `lanes()`) divide the current space into multiple sections along an axis and distribute them to children. This enables creating repeated elements like shelves, drawers, or compartments with flexible or fixed sizing. Combined with `repeat` and `insert` parameters, complex patterns can be built concisely.

See [section model](models-section.md) for section types and [space model](models-space.md) for space operations.

## Modules

Three subdivision modules operate on different axes:

- `columns(sections, ...)` - X axis (width)
- `rows(sections, ...)` - Z axis (height)
- `lanes(sections, ...)` - Y axis (depth)

All three share the same signature:

```openscad
columns(sections, space=$head, repeat=1, insert=[]) children();
rows(sections, space=$head, repeat=1, insert=[]) children();
lanes(sections, space=$head, repeat=1, insert=[]) children();
```

**Parameters:**
- `sections` - Section array defining subdivision
- `space` - Space to divide (default: `$head`)
- `repeat` - Number of times to repeat sections array (default: 1)
- `insert` - Sections placed between repetitions (default: `[]`)

## Section Types

**ABS(value, obj)** - Absolute dimension in mm
**FLEX(weight, obj)** - Flexible section with proportion weight (default weight: 1)
**DIV(obj)** - Divider using context material thickness

## Section Distribution

Sections are distributed to children based on the `obj` parameter.

### Round-Robin Distribution (default)

When no `obj` parameters are specified, sections distribute round-robin:

```openscad
columns([FLEX(), FLEX(), FLEX(), FLEX()]) {
  block(); // Gets sections 0, 3 (indices 0, 3)
  block(); // Gets sections 1 (indices 1)
}
```

Child 0 gets sections at indices 0, 2, 4, 6, ...
Child 1 gets sections at indices 1, 3, 5, 7, ...

### Object Mapping

When any section has `obj` defined, distribution switches to object-based mapping. Sections with `obj` go to the corresponding child index. Sections without `obj` are excluded.

```openscad
columns([ABS(50, obj=1), FLEX(obj=0), ABS(50, obj=1)]) {
  paint("Red") block();   // Child 0 gets FLEX (obj=0)
  paint("Blue") block();  // Child 1 gets both ABS (obj=1)
}
```

This allows:
- Multiple sections assigned to the same child
- Skipping sections (no child renders them)
- Flexible grouping patterns

## Repeat Parameter

The `repeat` parameter repeats the sections array multiple times:

```openscad
rows([FLEX()], repeat=3) {
  block(); // Creates: [FLEX(), FLEX(), FLEX()]
}
```

With round-robin distribution and one child, all three sections go to that child.

Multiple children with repeat:
```openscad
columns([FLEX(), FLEX()], repeat=2) {
  // Creates: [FLEX(), FLEX(), FLEX(), FLEX()]
  block(); // Gets sections 0, 2 (first and third)
  block(); // Gets sections 1, 3 (second and fourth)
}
```

## Insert Parameter

The `insert` parameter places sections between repetitions:

```openscad
rows([FLEX()], repeat=3, insert=[DIV()]) {
  // Creates: [FLEX(), DIV(), FLEX(), DIV(), FLEX()]
  block();
}
```

Inserters appear between repetitions but not before the first or after the last.

With 3 repetitions:
- Pattern: `sections + insert + sections + insert + sections`
- Result: 3 section blocks, 2 insert blocks

## Combining Repeat, Insert, and Obj

Using all three parameters together enables powerful patterns:

```openscad
rows([FLEX(obj=0)], repeat=4, insert=[DIV(obj=1)]) {
  // Creates: [FLEX(obj=0), DIV(obj=1), FLEX(obj=0), DIV(obj=1),
  //           FLEX(obj=0), DIV(obj=1), FLEX(obj=0)]
  paint("Blue") block();   // Gets all 4 FLEX sections (obj=0)
  paint("Gray") block();   // Gets all 3 DIV sections (obj=1)
}
```

Pattern breakdown:
1. `repeat=4` creates 4 copies of `[FLEX(obj=0)]`
2. `insert=[DIV(obj=1)]` places dividers between them
3. Result: 4 FLEX sections + 3 DIV sections
4. Child 0 (obj=0) renders all FLEX sections as a single block
5. Child 1 (obj=1) renders all DIV sections as a single block

Practical cabinet example:
```openscad
panel(BOTTOM) {
  panel(TOP) {
    // 3 shelves, bottom one shares outer bottom panel
    rows([FLEX()], repeat=3, insert=[DIV(obj=0)]) {
      panel(BOTTOM); // Only middle and top compartments get bottom panels
    }
  }
}
```

## Flexible Section Weights

FLEX sections can have different weights to control proportion:

```openscad
columns([FLEX(weight=1), FLEX(weight=2), FLEX(weight=1)]) {
  block(); // Gets 1/4 of space
  block(); // Gets 2/4 of space (twice as much)
  block(); // Gets 1/4 of space
}
```

Weights are relative. With total weight 4 and available space of 400mm:
- Weight 1 gets 100mm (400 * 1/4)
- Weight 2 gets 200mm (400 * 2/4)

## Complete Examples

Basic subdivision:
```openscad
columns([ABS(100), FLEX(), ABS(150)]) {
  block(); // 100mm fixed
  block(); // Remaining space
  block(); // 150mm fixed
}
```

Shelves with material dividers:
```openscad
material(MDF(16)) {
  rows([FLEX()], repeat=5, insert=[DIV(obj=0)]) {
    panel(BOTTOM);  // Creates 4 shelf panels between 5 compartments
  }
}
```

Drawers with fixed spacing:
```openscad
columns([FLEX(obj=0), ABS(20)], repeat=3) {
  // Creates: [FLEX(obj=0), 20, FLEX(obj=0), 20, FLEX(obj=0), 20]
  drawer(); // Gets all 3 FLEX sections, 20mm gaps are unassigned
}
```
