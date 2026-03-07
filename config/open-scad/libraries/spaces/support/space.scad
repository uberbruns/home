// Space construction function

// Function: space()
// Synopsis: Creates a space definition from individual parameters.
// Usage:
//   space([x], [y], [z], [width], [depth], [height]);
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
//   Space in format [[x, y, z], [width, depth, height]]
// Example:
//   my_space = space(width=600, depth=400, height=800);
//   // Returns [[0, 0, 0], [600, 400, 800]]
// Example:
//   my_space = space(x=100, y=50, z=20, width=300, depth=200, height=500);
//   // Returns [[100, 50, 20], [300, 200, 500]]
function space(x=0, y=0, z=0, width=0, depth=0, height=0) =
  [[x, y, z], [width, depth, height]];
