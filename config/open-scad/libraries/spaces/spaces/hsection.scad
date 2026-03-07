// Horizontal section modules for horizontal divisions

include <../objects/panel.scad>


// Module: hsection_left()
// Synopsis: Creates a vertical DIV panel on the left side of a space, with the DIV on the leading edge.
// Usage:
//   hsection_left(name, width, space, [thickness], [DIV]);
// Description:
//   Creates a vertical side panel at the specified width from the left edge of the given space.
//   The DIV is positioned on the leading (right) edge of the left section. The module sets
//   special variables $inside for the left section and $free for the right section, and
//   updates the $path variable for hierarchical naming.
// Arguments:
//   name = Name identifier for this horizontal section division
//   width = Width of the left section in millimeters
//   space = Space definition as [[x, y, z], [width, depth, height]]
//   ---
//   thickness = Panel thickness in millimeters. Default: $thickness
//   DIV = Whether to render the DIV panel. Default: true
// Special Variables:
//   Sets $inside = [[x, y, z], [width, depth, height]] for the left section
//   Sets $free = [[x, y, z], [width, depth, height]] for the right section
// Example:
//   hsection_left("Storage", 200, $inside)
//     children();
module hsection_left(name, width, space, thickness=$thickness, DIV=true) {
  space_pos = space[0];
  space_dim = space[1];

  t = DIV ? thickness : 0;
  $inside = [space_pos, [width, space_dim.y, space_dim.z]];
  $free = [[space_pos.x + width + t, space_pos.y, space_pos.z], [space_dim.x - width - t, space_dim.y, space_dim.z]];
  if (DIV) {
    color("LightSalmon")
      translate([space_pos.x + width, space_pos.y, space_pos.z])
        _side_panel(name, space_dim.y, space_dim.z, thickness);
  }
  children();
}


// Module: hsection_right()
// Synopsis: Creates a vertical DIV panel on the right side of a space, with the DIV on the leading edge.
// Usage:
//   hsection_right(name, width, space, [thickness], [DIV]);
// Description:
//   Creates a vertical side panel at the specified width from the right edge of the given space.
//   The DIV is positioned on the leading (left) edge of the right section. The module sets
//   special variables $inside for the right section and $free for the left section, and
//   updates the $path variable for hierarchical naming.
// Arguments:
//   name = Name identifier for this horizontal section division
//   width = Width of the right section in millimeters
//   space = Space definition as [[x, y, z], [width, depth, height]]
//   ---
//   thickness = Panel thickness in millimeters. Default: $thickness
//   DIV = Whether to render the DIV panel. Default: true
// Special Variables:
//   Sets $inside = [[x, y, z], [width, depth, height]] for the right section
//   Sets $free = [[x, y, z], [width, depth, height]] for the left section
// Example:
//   hsection_right("Shelves", 150, $inside)
//     children();
module hsection_right(name, width, space, thickness=$thickness, DIV=true) {
  space_pos = space[0];
  space_dim = space[1];

  t = DIV ? thickness : 0;
  panel_x = space_pos.x + space_dim.x - width - t;
  $inside = [[panel_x + t, space_pos.y, space_pos.z], [width, space_dim.y, space_dim.z]];
  $free = [space_pos, [space_dim.x - width - t, space_dim.y, space_dim.z]];
  if (DIV) {
    color("LightSalmon")
      translate([panel_x, space_pos.y, space_pos.z])
        _side_panel(name, space_dim.y, space_dim.z, thickness);
  }
  children();
}


// Module: hsection()
// Synopsis: Creates a vertical DIV panel on either the left or right side based on width sign.
// Usage:
//   hsection(name, width, space, [thickness], [DIV]);
// Description:
//   Creates a vertical side panel dividing a space into two sections. The position of the panel
//   is determined by the sign of the width parameter: positive values create a left-aligned section,
//   negative values create a right-aligned section. This module provides a unified interface for
//   both hsection_left() and hsection_right(). The DIV is positioned on the leading
//   edge of the inside section.
// Arguments:
//   name = Name identifier for this horizontal section division
//   width = Width of the section. Positive for left-aligned, negative for right-aligned
//   space = Space definition as [[x, y, z], [width, depth, height]]
//   ---
//   thickness = Panel thickness in millimeters. Default: $thickness
//   DIV = Whether to render the DIV panel. Default: true
// Special Variables:
//   Sets $inside = [[x, y, z], [width, depth, height]] for the section (left or right based on width sign)
//   Sets $free = [[x, y, z], [width, depth, height]] for the opposite section
// Example:
//   hsection("Left Section", 200, $inside)     // Left-aligned
//     children();
//   hsection("Right Section", -150, $inside)   // Right-aligned
//     children();
module hsection(name, width, space, thickness=$thickness, DIV=true) {
  if (width < 0) {
    hsection_right(name, -width, space, thickness, DIV)
      children();
  } else {
    hsection_left(name, width, space, thickness, DIV)
      children();
  }
}
