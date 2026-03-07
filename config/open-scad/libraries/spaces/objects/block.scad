// Block module for filling spaces with solid cubes

include <../support/echo_material.scad>
include <../support/quicksort.scad>

// Module: block()
// Synopsis: Creates a cube that fills the given space.
// Usage:
//   block(name, space);
// Description:
//   Creates a solid cube that completely fills the provided space. This is useful for
//   visualizing interior volumes or creating placeholder objects that occupy a space.
//   For material calculation, the dimensions are sorted: longest side becomes length,
//   middle dimension becomes width, and shortest side becomes thickness.
// Arguments:
//   name = Name identifier for the block
//   space = Space to fill, format: [[x, y, z], [width, depth, height]]
// Example:
//   cabinet("Test", 600, 500, 800) {
//     block("Interior Block", $inside);
//   }
module block(name, space) {
  space_pos = space[0];
  space_dim = space[1];

  // Sort dimensions: shortest = thickness, middle = width, longest = length
  sorted_dims = quicksort([space_dim.x, space_dim.y, space_dim.z]);

  thickness = sorted_dims[0];
  width = sorted_dims[1];
  length = sorted_dims[2];

  echo_material(name, length, width, thickness);

  translate([space_pos.x, space_pos.y, space_pos.z])
    cube([space_dim.x, space_dim.y, space_dim.z]);

  children();
}
