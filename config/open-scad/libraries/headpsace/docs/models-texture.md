# Texture Model

Textures control the visual appearance of rendered objects in the Headspace library. They combine color, transparency, and a layer value for precedence control. Textures are used directly via `paint()` or `texture()`, and indirectly through material definitions.

## Constructor

### texture_new()

Creates a texture vector.

```openscad
texture = texture_new(color, alpha=1.0, layer=1);
```

**Parameters:**
- `color` - Color value (string like `"Red"` or vector like `[1, 0, 0]`)
- `alpha` - Transparency (0.0 to 1.0, default: 1.0)
- `layer` - Rendering layer (default: 1)

**Returns:** Texture vector

## Getters

### texture_color()

```openscad
color = texture_color(texture);
```

Returns color value.

### texture_alpha()

```openscad
alpha = texture_alpha(texture);
```

Returns alpha transparency (0.0 to 1.0).

### texture_layer()

```openscad
layer = texture_layer(texture);
```

Returns layer value.

## Usage

Named color:
```openscad
tex = texture_new("Blue");
color(texture_color(tex), texture_alpha(tex)) cube([10, 10, 10]);
```

RGB color with transparency:
```openscad
tex = texture_new([1, 0, 0], alpha=0.5, layer=2);
```

Layer-based rendering:
```openscad
// Higher layer values override lower layers
base = texture_new("Gray", layer=0);
highlight = texture_new("Red", layer=1);
// highlight takes precedence when both are applied
```

Material texture:
```openscad
material = material_new(
  "Oak",
  18,
  texture=texture_new("BurlyWood", layer=0)
);
```
