# Section Model

Sections define how space is divided by the subdivision modules (`columns()`, `rows()`, `lanes()`). Each section specifies either an absolute dimension or a flexible proportion, and can be assigned to specific child objects. Sections enable precise control over space distribution in cabinet and furniture layouts.

## Constructor

### section_new()

Creates a section vector.

```openscad
section = section_new(raw_type, value, obj=undef);
```

**Parameters:**
- `raw_type` - Type string ("ABS" or "FLEX()")
- `value` - Numeric value (dimension for "ABS", weight for "FLEX()")
- `obj` - Object index (default: `undef`)

**Returns:** Section vector

## Factory Functions

### ABS()

Creates an absolute-dimension section.

```openscad
section = ABS(value, obj=undef);
```

**Parameters:**
- `value` - Absolute dimension in mm
- `obj` - Object index (default: `undef`)

**Returns:** Section vector

**Example:**
```openscad
ABS(100) // 100mm absolute section
ABS(50, obj=0) // 50mm section assigned to child 0
```

### FLEX()

Creates a flexible section with proportion weight.

```openscad
section = FLEX(weight=1, obj=undef);
```

**Parameters:**
- `weight` - Proportion weight (default: 1)
- `obj` - Object index (default: `undef`)

**Returns:** Section vector

**Example:**
```openscad
FLEX() // Weight 1
FLEX(weight=2) // Gets twice the space of weight 1
FLEX(weight=1, obj=0) // Assigned to child 0
```

### DIV()

Creates a divider section using context material thickness.

```openscad
section = DIV(obj=undef);
```

**Parameters:**
- `obj` - Object index (default: `undef`)

**Returns:** Section vector with thickness from `context_material(context_current())`

**Example:**
```openscad
material(MDF(16)) {
  columns([FLEX(), DIV(), FLEX()]) {
    block(); // Flexible
    block(); // 16mm divider
    block(); // Flexible
  }
}
```

## Getters

### section_raw_type()

```openscad
type = section_raw_type(section);
```

Returns type string ("ABS" or "FLEX()").

### section_value()

```openscad
value = section_value(section);
```

Returns numeric value (dimension for "ABS", weight for "FLEX()").

### section_obj()

```openscad
obj = section_obj(section);
```

Returns object index (may be `undef`).

## Type Checking

### section_is_abs()

```openscad
is_abs = section_is_abs(section);
```

Returns `true` if section type is "ABS".

### section_is_flex()

```openscad
is_flex = section_is_flex(section);
```

Returns `true` if section type is "FLEX()".

## Usage

Object index mapping:
```openscad
columns([ABS(50, obj=1), FLEX(obj=0), ABS(50, obj=1)]) {
  paint("Red") block();   // obj=0 → FLEX section
  paint("Blue") block();  // obj=1 → both ABS sections
}
```

Weight distribution:
```openscad
// Space: 300mm total, 100mm absolute
columns([ABS(100), FLEX(weight=1), FLEX(weight=2)]) {
  block(); // 100mm
  block(); // (300-100) * 1/3 = 66.67mm
  block(); // (300-100) * 2/3 = 133.33mm
}
```
