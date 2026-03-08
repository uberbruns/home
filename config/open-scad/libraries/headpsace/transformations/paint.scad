// Paint module for setting context paint from color parameters

include <../models/texture/texture.scad>
include <texture.scad>

// Module: paint()
// Synopsis: Sets the context paint and executes children.
// Description:
//   Sets the context to contain the given paint texture and executes child modules.
//   This updates the paint used for rendering components.
//   Only sets the paint if the new layer is higher than or equal to the current paint's layer.
// Arguments:
//   color = Color value (string like "Red" or vector like [1, 0, 0])
//   alpha = Alpha transparency value (0.0 to 1.0). Default: 1.0
//   layer = Layer value for rendering order. Default: 1
module paint(color, alpha = 1.0, layer = 1) {
  texture(texture_new(color, alpha, layer)) children();
}
