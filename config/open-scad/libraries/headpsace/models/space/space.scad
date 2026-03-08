// Space factory function and member accessors

// Function: space_new()
// Synopsis: Creates a space definition from individual parameters.
// Description:
//   Constructs a space in the standard format [[x, y, z], [width, depth, height]]
//   from individual parameters. All parameters default to 0, making it easy to
//   create spaces by only specifying the non-zero values.
// Arguments:
//   ---
//   x = X position coordinate. Default: 0
//   y = Y position coordinate. Default: 0
//   z = Z position coordinate. Default: 0
//   width = Width dimension (X axis). Default: 0
//   depth = Depth dimension (Y axis). Default: 0
//   height = Height dimension (Z axis). Default: 0
// Returns:
//   Space type
function space_new(x=0, y=0, z=0, width=0, depth=0, height=0) =
  [[x, y, z], [width, depth, height]];

// Function: space_position()
// Synopsis: Extracts the position vector from a space.
// Description:
//   Returns the position component of a space as [x, y, z].
// Arguments:
//   space = Space type
// Returns:
//   Position vector as [x, y, z]
function space_position(space) = space[0];

// Function: space_dimension()
// Synopsis: Extracts the dimension vector from a space.
// Description:
//   Returns the dimension component of a space as [width, depth, height].
// Arguments:
//   space = Space type
// Returns:
//   Dimension vector as [width, depth, height]
function space_dimension(space) = space[1];

// Function: space_x()
// Synopsis: Extracts the X position from a space vector.
// Description:
//   Returns the X coordinate of a space's position.
// Arguments:
//   space = Space type
// Returns:
//   Numeric X coordinate value
function space_x(space) = space_position(space)[0];

// Function: space_y()
// Synopsis: Extracts the Y position from a space vector.
// Description:
//   Returns the Y coordinate of a space's position.
// Arguments:
//   space = Space type
// Returns:
//   Numeric Y coordinate value
function space_y(space) = space_position(space)[1];

// Function: space_z()
// Synopsis: Extracts the Z position from a space vector.
// Description:
//   Returns the Z coordinate of a space's position.
// Arguments:
//   space = Space type
// Returns:
//   Numeric Z coordinate value
function space_z(space) = space_position(space)[2];

// Function: space_width()
// Synopsis: Extracts the width dimension from a space vector.
// Description:
//   Returns the width (X dimension) of a space.
// Arguments:
//   space = Space type
// Returns:
//   Numeric width value
function space_width(space) = space_dimension(space)[0];

// Function: space_depth()
// Synopsis: Extracts the depth dimension from a space vector.
// Description:
//   Returns the depth (Y dimension) of a space.
// Arguments:
//   space = Space type
// Returns:
//   Numeric depth value
function space_depth(space) = space_dimension(space)[1];

// Function: space_height()
// Synopsis: Extracts the height dimension from a space vector.
// Description:
//   Returns the height (Z dimension) of a space.
// Arguments:
//   space = Space type
// Returns:
//   Numeric height value
function space_height(space) = space_dimension(space)[2];
