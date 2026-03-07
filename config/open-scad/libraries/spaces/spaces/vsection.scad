// Vertical section modules for vertical divisions

include <../objects/panel.scad>


// Module: vsection_bottom()
// Synopsis: Creates a vertical section space aligned to the bottom, dividing vertically without a physical shelf.
// Usage:
//   vsection_bottom(name, space, [height]);
// Description:
//   Divides a space vertically into a lower section and an upper free space without
//   rendering any physical shelf. This is a pure space-division module. The section height
//   can be specified or defaults to the full space height. Use the shelf() module if you need
//   a physical shelf panel.
// Arguments:
//   name = Name identifier for the vertical section
//   space = Space definition as [[x, y, z], [width, depth, height]]
//   ---
//   height = Height of the section in millimeters. Default: full space height
// Special Variables:
//   Sets $inside = [[x, y, z], [width, depth, height]] for the section space
//   Sets $free = [[x, y, z], [width, depth, height]] for the space above the section
// Example:
//   vsection_bottom("Storage", $inside, height=200)
//     children();
module vsection_bottom(name, space, height=undef) {
  space_pos = space[0];
  space_dim = space[1];
  h = height == undef ? space_dim.z : height;

  $inside = [space_pos, [space_dim.x, space_dim.y, h]];
  $free = [[space_pos.x, space_pos.y, space_pos.z + h], [space_dim.x, space_dim.y, space_dim.z - h]];
  children();
}


// Module: vsection_top()
// Synopsis: Creates a vertical section space aligned to the top, dividing vertically without a physical shelf.
// Usage:
//   vsection_top(name, space, [height]);
// Description:
//   Divides a space vertically into an upper section and a lower free space without
//   rendering any physical shelf. This is a pure space-division module. The section height
//   can be specified or defaults to the full space height. Use the shelf() module if you need
//   a physical shelf panel.
// Arguments:
//   name = Name identifier for the vertical section
//   space = Space definition as [[x, y, z], [width, depth, height]]
//   ---
//   height = Height of the section in millimeters. Default: full space height
// Special Variables:
//   Sets $inside = [[x, y, z], [width, depth, height]] for the section space
//   Sets $free = [[x, y, z], [width, depth, height]] for the space below the section
// Example:
//   vsection_top("Upper Storage", $inside, height=150)
//     children();
module vsection_top(name, space, height=undef) {
  space_pos = space[0];
  space_dim = space[1];
  h = height == undef ? space_dim.z : height;

  compartment_z = space_pos.z + space_dim.z - h;
  $inside = [[space_pos.x, space_pos.y, compartment_z], [space_dim.x, space_dim.y, h]];
  $free = [space_pos, [space_dim.x, space_dim.y, space_dim.z - h]];
  children();
}


// Module: vsection()
// Synopsis: Creates a vertical section space aligned to either bottom or top based on height sign.
// Usage:
//   vsection(name, space, [height]);
// Description:
//   Divides a space vertically without rendering any physical shelf. The alignment is determined
//   by the sign of the height parameter: positive values create a bottom-aligned section,
//   negative values create a top-aligned section. This module provides a unified interface
//   for both vsection_bottom() and vsection_top(). The $free variable
//   contains the space not occupied by the section (above for bottom-aligned, below for top-aligned).
//   Use the shelf() module if you need a physical shelf panel.
// Arguments:
//   name = Name identifier for the vertical section
//   space = Space definition as [[x, y, z], [width, depth, height]]
//   ---
//   height = Height of the section. Positive for bottom-aligned, negative for top-aligned. Default: full space height
// Special Variables:
//   Sets $inside = [[x, y, z], [width, depth, height]] for the section space
//   Sets $free = [[x, y, z], [width, depth, height]] for the space not occupied by section
// Example:
//   vsection("Lower Shelf", $inside, height=200)    // Bottom-aligned
//     children();
//   vsection("Upper Shelf", $inside, height=-150)   // Top-aligned
//     children();
module vsection(name, space, height=undef) {
  if (height != undef && height < 0) {
    vsection_top(name, space, -height)
      children();
  } else {
    vsection_bottom(name, space, height)
      children();
  }
}
