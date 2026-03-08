// Context module for hierarchical naming

include <../texture/texture.scad>
include <../material/material.scad>

// Function: context_new()
// Synopsis: Creates a context vector from name components, paint, material, depth, and render_depth.
// Description:
//   Constructs a context vector. This is the canonical constructor for creating context vectors programmatically.
// Arguments:
//   name_components = List of name component strings
//   paint = Paint texture vector. Default: undef
//   material = Material vector. Default: DEFAULT_MATERIAL(16)
//   depth = Depth value. Default: 0
//   render_depth = Maximum depth to render. Default: 9999
// Returns:
//   Context vector
function context_new(name_components = [], paint = undef, material = undef, depth = 0, render_depth = 9999) =
  let(resolved_material = material == undef ? DEFAULT_MATERIAL(16) : material)
  [
    name_components,
    paint,
    resolved_material,
    depth,
    render_depth
  ];

// Initialize global context stack
$context_stack = [context_new()];

// Function: context_current()
// Synopsis: Returns the current context from the top of the stack.
// Returns:
//   Current context vector (last element in the stack)
function context_current() = $context_stack[len($context_stack) - 1];

// Function: context_push()
// Synopsis: Pushes a context onto the context stack.
// Arguments:
//   context = Context vector to push
// Returns:
//   New context stack with the context appended
function context_push(context) = concat($context_stack, [context]);

// Function: context_pop()
// Synopsis: Pops the last context from the context stack.
// Returns:
//   New context stack with the last element removed
function context_pop() =
  let(count = len($context_stack))
  count > 1 ? [for (i = [0:count-2]) $context_stack[i]] : $context_stack;

// Function: context_pop_preserve_depth()
// Synopsis: Pops the last context from the stack and sets the depth of the restored context to the depth of the popped context.
// Description:
//   When restoring a context by popping the stack, this function preserves the depth value from the context being removed
//   and applies it to the context that becomes current after the pop.
// Returns:
//   New context stack with the last element removed and the new current context's depth set to the previous depth
function context_pop_preserve_depth() =
  let(
    count = len($context_stack),
    current_depth = context_depth(context_current())
  )
  count > 1
    ? concat(
        [for (i = [0:count-3]) $context_stack[i]],
        [context_depth_set($context_stack[count-2], current_depth)]
      )
    : $context_stack;

// Function: context_update()
// Synopsis: Replaces the current context (last element in stack) with a new context.
// Arguments:
//   context = Context vector to replace the current context with
// Returns:
//   New context stack with the last element replaced
function context_update(context) =
  let(count = len($context_stack))
  count > 1 ? concat([for (i = [0:count-2]) $context_stack[i]], [context]) : [context];

// Function: context_name()
// Synopsis: Joins name components into a fully qualified name.
// Arguments:
//   context = Context vector
// Returns:
//   String with name components joined by "/"
function context_name(context) = _join(context_name_components(context), "/");

// Function: context_name_components()
// Synopsis: Extracts the name_components from a context vector.
// Arguments:
//   context = Context vector
// Returns:
//   List of name component strings
function context_name_components(context) = context[0];

// Function: context_name_components_pop()
// Synopsis: Pops the last name component from a context and returns a new context.
// Arguments:
//   context = Context vector
// Returns:
//   New context vector with the last name component removed
function context_name_components_pop(context) =
  let(
    components = context_name_components(context),
    count = len(components)
  )
  count > 0
    ? context_new([for (i = [0:count-2]) components[i]], context_paint(context), context_material(context), context_depth(context), context_render_depth(context))
    : context;

// Function: context_name_components_push()
// Synopsis: Pushes a name component to a context and returns a new context.
// Arguments:
//   context = Context vector
//   name_component = Name component string to push_name
// Returns:
//   New context vector with the pushed name component
function context_name_components_push(context, name_component) =
  context_new(concat(context_name_components(context), [name_component]), context_paint(context), context_material(context), context_depth(context), context_render_depth(context));

// Function: context_name_components_set()
// Synopsis: Sets the name_components in a context and returns a new context.
// Arguments:
//   context = Context vector
//   name_components = List of name component strings to set
// Returns:
//   New context vector with the specified name components
function context_name_components_set(context, name_components) =
  context_new(name_components, context_paint(context), context_material(context), context_depth(context), context_render_depth(context));

// Function: context_material()
// Synopsis: Extracts the material from a context vector.
// Arguments:
//   context = Context vector
// Returns:
//   Material vector (may be undefined)
function context_material(context) = context[2];

// Function: context_material_set()
// Synopsis: Sets the material in a context and returns a new context.
// Arguments:
//   context = Context vector
//   material = Material vector to set
// Returns:
//   New context vector with the specified material
function context_material_set(context, material) =
  context_new(context_name_components(context), context_paint(context), material, context_depth(context), context_render_depth(context));

// Function: context_paint()
// Synopsis: Extracts the paint from a context vector.
// Arguments:
//   context = Context vector
// Returns:
//   Paint texture vector (may be undefined)
function context_paint(context) = context[1];

// Function: context_paint_set()
// Synopsis: Sets the paint in a context and returns a new context.
// Arguments:
//   context = Context vector
//   paint = Paint texture vector to set
// Returns:
//   New context vector with the specified paint
function context_paint_set(context, paint) =
  context_new(context_name_components(context), paint, context_material(context), context_depth(context), context_render_depth(context));

// Function: context_depth()
// Synopsis: Extracts the depth from a context vector.
// Arguments:
//   context = Context vector
// Returns:
//   Depth value (numeric)
function context_depth(context) = context[3];

// Function: context_depth_set()
// Synopsis: Sets the depth in a context and returns a new context.
// Arguments:
//   context = Context vector
//   depth = Depth value to set
// Returns:
//   New context vector with the specified depth
function context_depth_set(context, depth) =
  context_new(context_name_components(context), context_paint(context), context_material(context), depth, context_render_depth(context));

// Function: context_depth_increment()
// Synopsis: Increments the depth in a context and returns a new context.
// Arguments:
//   context = Context vector
// Returns:
//   New context vector with depth incremented by 1
function context_depth_increment(context, i = 1) =
  context_new(context_name_components(context), context_paint(context), context_material(context), context_depth(context) + i, context_render_depth(context));

// Function: context_render_depth()
// Synopsis: Extracts the render_depth from a context vector.
// Arguments:
//   context = Context vector
// Returns:
//   Render depth value (numeric)
function context_render_depth(context) = context[4];

// Function: context_render_depth_set()
// Synopsis: Sets the render_depth in a context and returns a new context.
// Arguments:
//   context = Context vector
//   render_depth = Maximum depth to render
// Returns:
//   New context vector with the specified render_depth
function context_render_depth_set(context, render_depth) =
  context_new(context_name_components(context), context_paint(context), context_material(context), context_depth(context), render_depth);

// Function: context_texture()
// Synopsis: Extracts the effective texture from a context vector, with default fallback.
// Arguments:
//   context = Context vector
// Returns:
//   Texture vector (returns texture with highest layer from paint or material, otherwise default OrangeRed texture)
function context_texture(context) =
  let(
    paint = context_paint(context),
    mat = context_material(context),
    mat_texture = mat == undef ? undef : material_texture(mat),
    paint_layer = paint == undef ? -1 : texture_layer(paint),
    mat_texture_layer = mat_texture == undef ? -1 : texture_layer(mat_texture)
  )
  paint_layer == -1 && mat_texture_layer == -1 ? texture_new("OrangeRed") :
  paint_layer >= mat_texture_layer ? paint : mat_texture;

// Helper function to join list elements with separator
function _join(list, sep, i=0, acc="") =
  i >= len(list) ? acc :
  i == 0 ? _join(list, sep, i+1, list[i]) :
  _join(list, sep, i+1, str(acc, sep, list[i]));
