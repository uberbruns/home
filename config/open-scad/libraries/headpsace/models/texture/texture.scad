// Texture model for color representation

// Function: texture_new()
// Synopsis: Creates a texture vector from color, alpha, and layer values.
// Description:
//   Constructs a texture vector. This is the canonical constructor for creating texture vectors programmatically.
// Arguments:
//   color = Color value (string like "Red" or vector like [1, 0, 0])
//   alpha = Alpha transparency value (0.0 to 1.0). Default: 1.0
//   layer = Layer value for rendering order. Default: 1
// Returns:
//   Texture vector
function texture_new(color, alpha = 1.0, layer = 1) = [color, alpha, layer];

// Function: texture_color()
// Synopsis: Extracts the color value from a texture vector.
// Arguments:
//   texture = Texture vector
// Returns:
//   Color value
function texture_color(texture) = texture[0];

// Function: texture_alpha()
// Synopsis: Extracts the alpha value from a texture vector.
// Arguments:
//   texture = Texture vector
// Returns:
//   Alpha transparency value (0.0 to 1.0)
function texture_alpha(texture) = texture[1];

// Function: texture_layer()
// Synopsis: Extracts the layer value from a texture vector.
// Arguments:
//   texture = Texture vector
// Returns:
//   Layer value
function texture_layer(texture) = texture[2];
