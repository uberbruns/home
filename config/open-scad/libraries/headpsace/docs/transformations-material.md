# material()

The `material()` module sets the active material in the context for all children. This determines panel thickness, divider dimensions, and default textures. Materials flow through the module tree until overridden by another `material()` call.

See [material model](models-material.md) for material vector operations.

```openscad
material(material) children();
```

**Parameters:**
- `material` - Material vector (if `undef`, children render unchanged)

**Usage:**

```openscad
material(MDF(16)) {
  block(); // Renders with 16mm MDF material
}
```

Material affects thickness in operations like `panel()` and `DIV()`, and provides default texture for rendering.
