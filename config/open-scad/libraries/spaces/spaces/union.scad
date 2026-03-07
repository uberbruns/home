// Space union function for combining spaces

// Function: space_union()
// Synopsis: Creates a space that encompasses two input spaces.
// Usage:
//   result_space = space_union(space1, space2);
// Description:
//   Combines two space definitions into a single space that circumvents both input spaces.
//   The resulting space starts at the minimum x, y, z coordinates of both spaces and extends
//   to the maximum x, y, z coordinates of both spaces. Similar to OpenSCAD's hull() but for
//   space definitions rather than geometry.
// Arguments:
//   space1 = First space definition as [[x, y, z], [width, depth, height]]
//   space2 = Second space definition as [[x, y, z], [width, depth, height]]
// Returns:
//   Combined space as [[x, y, z], [width, depth, height]]
// Example:
//   space1 = [[0, 0, 0], [100, 100, 100]];
//   space2 = [[50, 50, 50], [100, 100, 100]];
//   combined = space_union(space1, space2);
//     // Returns: [[0, 0, 0], [150, 150, 150]]
function space_union(space1, space2) =
  let(
    pos1 = space1[0],
    dim1 = space1[1],
    pos2 = space2[0],
    dim2 = space2[1],

    // Calculate minimum coordinates (start of combined space)
    min_x = min(pos1.x, pos2.x),
    min_y = min(pos1.y, pos2.y),
    min_z = min(pos1.z, pos2.z),

    // Calculate maximum coordinates (end of each space)
    max1_x = pos1.x + dim1.x,
    max1_y = pos1.y + dim1.y,
    max1_z = pos1.z + dim1.z,
    max2_x = pos2.x + dim2.x,
    max2_y = pos2.y + dim2.y,
    max2_z = pos2.z + dim2.z,

    // Calculate maximum coordinates (end of combined space)
    max_x = max(max1_x, max2_x),
    max_y = max(max1_y, max2_y),
    max_z = max(max1_z, max2_z),

    // Calculate dimensions of combined space
    width = max_x - min_x,
    depth = max_y - min_y,
    height = max_z - min_z
  )
  [[min_x, min_y, min_z], [width, depth, height]];
