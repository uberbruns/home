// Texture module for setting context paint from a texture

include <../models/context/context.scad>
include <../models/texture/texture.scad>
include <context.scad>

// Module: texture()
// Synopsis: Sets the context paint from a texture and executes children.
// Description:
//   Sets the context to contain the given texture as paint and executes child modules.
//   This updates the paint used for rendering components.
//   Only sets the paint if the texture's layer is higher than or equal to the current paint's layer.
// Arguments:
//   texture = Texture vector
module texture(texture) {
  current_paint = context_paint(context_current());
  current_layer = current_paint == undef ? -1 : texture_layer(current_paint);
  new_layer = texture == undef ? -1 : texture_layer(texture);

  if (new_layer >= current_layer) {
    update(context_paint_set(context_current(), texture)) children();
  } else {
    children();
  }
}
