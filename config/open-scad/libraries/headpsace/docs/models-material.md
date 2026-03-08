# Material Model

Materials define the physical properties of panels and dividers in the Headspace library. They specify thickness (used by `panel()` and `DIV()`), base texture, and optional veneer layers for realistic panel rendering. Materials are stored in the context and flow through the module tree.

## Constructor

### material_new()

Creates a material vector.

```openscad
material = material_new(name, thickness, texture=undef, veneer_texture=undef,
                        veneer_front=0, veneer_back=0);
```

**Parameters:**
- `name` - Name identifier string
- `thickness` - Thickness in mm
- `texture` - Texture vector (default: `undef`)
- `veneer_texture` - Veneer texture vector (default: `undef`)
- `veneer_front` - Front veneer thickness in mm (default: 0)
- `veneer_back` - Back veneer thickness in mm (default: 0)

**Returns:** Material vector

## Getters

### material_name()

```openscad
name = material_name(material);
```

Returns name string.

### material_thickness()

```openscad
thickness = material_thickness(material);
```

Returns thickness in mm.

### material_texture()

```openscad
texture = material_texture(material);
```

Returns texture vector (may be `undef`).

### material_veneer_texture()

```openscad
veneer_texture = material_veneer_texture(material);
```

Returns veneer texture vector (may be `undef`).

### material_veneer_front()

```openscad
veneer_front = material_veneer_front(material);
```

Returns front veneer thickness in mm (returns 0 if `undef`).

### material_veneer_back()

```openscad
veneer_back = material_veneer_back(material);
```

Returns back veneer thickness in mm (returns 0 if `undef`).

## Setters

All setters return new material vectors with updated properties.

### material_veneer_texture_set()

```openscad
new_material = material_veneer_texture_set(material, veneer_texture);
```

Sets veneer texture.

### material_veneer_front_set()

```openscad
new_material = material_veneer_front_set(material, veneer_front);
```

Sets front veneer thickness.

### material_veneer_back_set()

```openscad
new_material = material_veneer_back_set(material, veneer_back);
```

Sets back veneer thickness.

## Factory Functions

### MDF()

```openscad
material = MDF(thickness);
```

Creates MDF material with tan texture.

**Parameters:**
- `thickness` - Thickness in mm

**Returns:** Material vector

### DEFAULT_MATERIAL()

```openscad
material = DEFAULT_MATERIAL(thickness);
```

Creates default material with gray texture at layer -1000, allowing override by any paint or material texture.

**Parameters:**
- `thickness` - Thickness in mm

**Returns:** Material vector

## Usage

Creating custom material:
```openscad
plywood = material_new(
  "Plywood",
  18,
  texture=texture_new("BurlyWood"),
  veneer_texture=texture_new("SaddleBrown"),
  veneer_front=0.6,
  veneer_back=0.6
);
```
