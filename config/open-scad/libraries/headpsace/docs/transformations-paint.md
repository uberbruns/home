# paint()

The `paint()` module sets the visual color for rendered objects. It's a convenience wrapper around `texture()` that accepts color parameters directly. Paint uses a layer system where higher layers override lower ones, allowing base colors to be selectively overridden.

See [texture model](models-texture.md) for texture vector operations.

```openscad
paint(color, alpha=1.0, layer=1) children();
```

**Parameters:**
- `color` - Color value (string like `"Red"` or vector like `[1, 0, 0]`)
- `alpha` - Transparency (0.0 to 1.0, default: 1.0)
- `layer` - Rendering layer (default: 1)

Only applies if the new layer is ≥ current paint layer.

**Usage:**

```openscad
paint("Blue") {
  block(); // Blue block
}
```

With transparency:
```openscad
paint("Red", alpha=0.5) {
  block(); // Semi-transparent red
}
```

Layer precedence:
```openscad
paint("Red", layer=0) {
  block(); // Red
  paint("Blue", layer=1) {
    block(); // Blue (higher layer wins)
  }
  paint("Green", layer=0) {
    block(); // Red (layer 0 doesn't override layer 0)
  }
}
```
