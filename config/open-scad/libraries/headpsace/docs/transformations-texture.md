# texture()

The `texture()` module sets the visual appearance for rendered objects in the context. It accepts a texture vector with color, alpha, and layer properties. This is the primary mechanism for controlling appearance, especially when working with textures from material definitions.

See [texture model](models-texture.md) for texture vector operations.

```openscad
texture(texture) children();
```

**Parameters:**
- `texture` - Texture vector

Only applies if texture's layer is ≥ current context texture layer.

**Usage:**

```openscad
texture(texture_new("Green", alpha=0.7, layer=2)) {
  block(); // Rendered with green texture
}
```

Layer-based override:
```openscad
texture(texture_new("Red", layer=0)) {
  block(); // Red
  texture(texture_new("Blue", layer=1)) {
    block(); // Blue (layer 1 > layer 0)
  }
}
```

Using material veneer texture:
```openscad
material(MDF(16)) {
  veneer_tex = material_veneer_texture(context_material(context_current()));
  texture(veneer_tex) {
    block(); // Rendered with veneer texture
  }
}
```

For simple color changes where other texture properties (alpha, layer) should use defaults, see `paint()` as a convenience alternative.
