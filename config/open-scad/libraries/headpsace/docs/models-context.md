# Context Model

The context model manages the rendering state that flows through the module tree. It stores hierarchical naming (for component identification), paint (for visual appearance), and material (for thickness and texture). The context stack allows saving and restoring state, enabling local modifications that don't affect sibling or parent modules.

## Global

`$context_stack` - Initialized with default context. Modified by transformation modules.

## Constructor

### context_new()

Creates a context vector.

```openscad
context = context_new(name_components=[], paint=undef, material=undef);
```

**Parameters:**
- `name_components` - List of name strings (default: `[]`)
- `paint` - Paint texture vector (default: `undef`)
- `material` - Material vector (default: `DEFAULT_MATERIAL(16)`)

**Returns:** Context vector

## Stack Operations

### context_current()

```openscad
context = context_current();
```

Returns the current context from the stack top.

### context_push()

```openscad
new_stack = context_push(context);
```

Returns new stack with context appended.

### context_pop()

```openscad
new_stack = context_pop();
```

Returns new stack with last element removed (minimum stack size: 1).

### context_update()

```openscad
new_stack = context_update(context);
```

Returns new stack with last element replaced by context.

## Getters

### context_name()

```openscad
name = context_name(context);
```

Returns name components joined by "/".

### context_name_components()

```openscad
components = context_name_components(context);
```

Returns list of name component strings.

### context_material()

```openscad
material = context_material(context);
```

Returns material vector.

### context_paint()

```openscad
paint = context_paint(context);
```

Returns paint texture vector (may be `undef`).

### context_texture()

```openscad
texture = context_texture(context);
```

Returns effective texture, choosing highest layer from paint or material texture. Falls back to `texture_new("OrangeRed")` if neither defined.

## Setters

All setters return new context vectors with updated properties.

### context_name_components_set()

```openscad
new_context = context_name_components_set(context, name_components);
```

Sets name components list.

### context_name_components_push()

```openscad
new_context = context_name_components_push(context, name_component);
```

Appends name component to hierarchy.

### context_name_components_pop()

```openscad
new_context = context_name_components_pop(context);
```

Removes last name component.

### context_material_set()

```openscad
new_context = context_material_set(context, material);
```

Sets material.

### context_paint_set()

```openscad
new_context = context_paint_set(context, paint);
```

Sets paint texture.

## Usage

Reading effective texture:
```openscad
ctx = context_current();
tex = context_texture(ctx);
color(texture_color(tex), texture_alpha(tex)) cube([10, 10, 10]);
```

Building hierarchical name:
```openscad
ctx = context_new();
ctx = context_name_components_push(ctx, "Cabinet");
ctx = context_name_components_push(ctx, "Shelf");
name = context_name(ctx); // "Cabinet/Shelf"
```
