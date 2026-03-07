// Panel modules for cabinet construction

include <../support/echo_material.scad>


// Module: _flat_panel()
// Synopsis: Creates a flat rectangular panel oriented horizontally (e.g., for shelves, tops, bottoms).
// Usage:
//   _flat_panel(name, width, depth, [thickness]);
// Description:
//   Creates a flat panel with the specified dimensions. The panel is oriented with width in
//   the X direction, depth in the Y direction, and thickness in the Z direction. This orientation
//   is suitable for horizontal surfaces like shelves, cabinet tops, and cabinet bottoms. The
//   module outputs material information via echo_material().
// Arguments:
//   name = Name identifier for the panel
//   width = Panel width (X dimension) in millimeters
//   depth = Panel depth (Y dimension) in millimeters
//   ---
//   thickness = Panel thickness (Z dimension) in millimeters. Default: $thickness
// Example:
//   _flat_panel("Shelf", 600, 400, 18);
module _flat_panel(name, width, depth, thickness=$thickness) {
  echo_material(name, width, depth, thickness);
  color("Blue")
    cube([width, depth, thickness]);
}


// Module: bottom_panel()
// Synopsis: Creates a flat panel at the bottom of the given space.
// Usage:
//   bottom_panel(name, space, [thickness]);
// Description:
//   Creates a flat panel positioned at the bottom of the given space definition. The panel
//   occupies the bottom of the space with the specified thickness. The space above the panel
//   is made available through the $free special variable for children modules.
// Arguments:
//   name = Name identifier for the panel
//   space = Space definition as [[x, y, z], [width, depth, height]]
//   ---
//   thickness = Panel thickness in millimeters. Default: $thickness
// Special Variables:
//   Sets $free = [[x, y, z], [width, depth, height]] for the space above the panel
// Example:
//   bottom_panel("Bottom", $inside);
module bottom_panel(name, space, thickness=$thickness) {
  space_pos = space[0];
  space_dim = space[1];

  $free = [[space_pos.x, space_pos.y, space_pos.z + thickness], [space_dim.x, space_dim.y, space_dim.z - thickness]];

  translate(space_pos)
    _flat_panel(name, space_dim.x, space_dim.y, thickness);

  children();
}


// Module: top_panel()
// Synopsis: Creates a flat panel at the top of the given space.
// Usage:
//   top_panel(name, space, [thickness]);
// Description:
//   Creates a flat panel positioned at the top of the given space definition. The panel
//   occupies the top of the space with the specified thickness. The space below the panel
//   is made available through the $free special variable for children modules.
// Arguments:
//   name = Name identifier for the panel
//   space = Space definition as [[x, y, z], [width, depth, height]]
//   ---
//   thickness = Panel thickness in millimeters. Default: $thickness
// Special Variables:
//   Sets $free = [[x, y, z], [width, depth, height]] for the space below the panel
// Example:
//   top_panel("Top", $inside);
module top_panel(name, space, thickness=$thickness) {
  space_pos = space[0];
  space_dim = space[1];

  $free = [space_pos, [space_dim.x, space_dim.y, space_dim.z - thickness]];

  translate([space_pos.x, space_pos.y, space_pos.z + space_dim.z - thickness])
    _flat_panel(name, space_dim.x, space_dim.y, thickness);

  children();
}


// Module: flat_panel()
// Synopsis: Creates a flat panel at the bottom or top based on thickness sign.
// Usage:
//   flat_panel(name, space, [thickness]);
// Description:
//   Creates a flat panel positioned at either the bottom or top of the given space based on
//   the sign of the thickness parameter. Positive thickness creates a bottom-aligned panel,
//   negative thickness creates a top-aligned panel using the absolute value. This provides
//   a unified interface for both bottom_panel() and top_panel().
// Arguments:
//   name = Name identifier for the panel
//   space = Space definition as [[x, y, z], [width, depth, height]]
//   ---
//   thickness = Panel thickness in millimeters. Positive: bottom-aligned, Negative: top-aligned. Default: $thickness
// Special Variables:
//   Sets $free = [[x, y, z], [width, depth, height]] for the space not occupied by the panel
// Example:
//   flat_panel("Bottom", $inside, 10);     // Bottom-aligned
//   flat_panel("Top", $inside, -10);       // Top-aligned
module flat_panel(name, space, thickness=$thickness) {
  if (thickness < 0) {
    top_panel(name, space, abs(thickness))
      children();
  } else {
    bottom_panel(name, space, thickness)
      children();
  }
}


// Module: _face_panel()
// Synopsis: Creates a vertical rectangular panel facing forward (e.g., for cabinet fronts, backs, doors).
// Usage:
//   _face_panel(name, width, height, [thickness]);
// Description:
//   Creates a face-oriented panel with the specified dimensions. The panel is oriented with
//   width in the X direction, thickness in the Y direction, and height in the Z direction.
//   This orientation is suitable for vertical surfaces like cabinet fronts, backs, and doors.
//   The module outputs material information via echo_material().
// Arguments:
//   name = Name identifier for the panel
//   width = Panel width (X dimension) in millimeters
//   height = Panel height (Z dimension) in millimeters
//   ---
//   thickness = Panel thickness (Y dimension) in millimeters. Default: $thickness
// Example:
//   _face_panel("Front", 600, 800, 18);
module _face_panel(name, width, height, thickness=$thickness) {
  // Face orientation: width in X, thickness in Y, height in Z
  echo_material(name, width, height, thickness);
  color("Green")
    cube([width, thickness, height]);
}


// Module: front_panel()
// Synopsis: Creates a face panel at the front (leading edge) of the given space.
// Usage:
//   front_panel(name, space, [thickness]);
// Description:
//   Creates a face-oriented panel positioned at the front (leading edge) of the given space.
//   The panel occupies the front of the space with the specified thickness. The space behind
//   the panel is made available through the $free special variable for children modules.
// Arguments:
//   name = Name identifier for the panel
//   space = Space definition as [[x, y, z], [width, depth, height]]
//   ---
//   thickness = Panel thickness in millimeters. Default: $thickness
// Special Variables:
//   Sets $free = [[x, y, z], [width, depth, height]] for the space behind the panel
// Example:
//   front_panel("Front", $inside);
module front_panel(name, space, thickness=$thickness) {
  space_pos = space[0];
  space_dim = space[1];

  $free = [[space_pos.x, space_pos.y + thickness, space_pos.z], [space_dim.x, space_dim.y - thickness, space_dim.z]];

  translate(space_pos)
    _face_panel(name, space_dim.x, space_dim.z, thickness);

  children();
}


// Module: back_panel()
// Synopsis: Creates a face panel at the back (trailing edge) of the given space.
// Usage:
//   back_panel(name, space, [thickness]);
// Description:
//   Creates a face-oriented panel positioned at the back (trailing edge) of the given space.
//   The panel occupies the back of the space with the specified thickness. The space in front
//   of the panel is made available through the $free special variable for children modules.
// Arguments:
//   name = Name identifier for the panel
//   space = Space definition as [[x, y, z], [width, depth, height]]
//   ---
//   thickness = Panel thickness in millimeters. Default: $thickness
// Special Variables:
//   Sets $free = [[x, y, z], [width, depth, height]] for the space in front of the panel
// Example:
//   back_panel("Back", $inside);
module back_panel(name, space, thickness=$thickness) {
  space_pos = space[0];
  space_dim = space[1];

  $free = [space_pos, [space_dim.x, space_dim.y - thickness, space_dim.z]];

  translate([space_pos.x, space_pos.y + space_dim.y - thickness, space_pos.z])
    _face_panel(name, space_dim.x, space_dim.z, thickness);

  children();
}


// Module: face_panel()
// Synopsis: Creates a face panel at the front or back based on thickness sign.
// Usage:
//   face_panel(name, space, [thickness]);
// Description:
//   Creates a face panel positioned at either the front (leading edge) or back (trailing edge)
//   of the given space based on the sign of the thickness parameter. Positive thickness creates
//   a front-aligned panel, negative thickness creates a back-aligned panel using the absolute value.
//   This provides a unified interface for both front_panel() and back_panel().
// Arguments:
//   name = Name identifier for the panel
//   space = Space definition as [[x, y, z], [width, depth, height]]
//   ---
//   thickness = Panel thickness in millimeters. Positive: front-aligned, Negative: back-aligned. Default: $thickness
// Special Variables:
//   Sets $free = [[x, y, z], [width, depth, height]] for the space not occupied by the panel
// Example:
//   face_panel("Front", $inside, 10);     // Front-aligned
//   face_panel("Back", $inside, -10);     // Back-aligned
module face_panel(name, space, thickness=$thickness) {
  if (thickness < 0) {
    back_panel(name, space, abs(thickness))
      children();
  } else {
    front_panel(name, space, thickness)
      children();
  }
}


// Module: _side_panel()
// Synopsis: Creates a vertical rectangular panel oriented as a side edge (e.g., for cabinet sides, DIVs).
// Usage:
//   _side_panel(name, depth, height, [thickness]);
// Description:
//   Creates a side-oriented panel with the specified dimensions. The panel is oriented with
//   thickness in the X direction, depth in the Y direction, and height in the Z direction.
//   This orientation is suitable for vertical edges like cabinet sides and interior DIVs.
//   The module outputs material information via echo_material().
// Arguments:
//   name = Name identifier for the panel
//   depth = Panel depth (Y dimension) in millimeters
//   height = Panel height (Z dimension) in millimeters
//   ---
//   thickness = Panel thickness (X dimension) in millimeters. Default: $thickness
// Example:
//   _side_panel("Left Side", 400, 800, 18);
module _side_panel(name, depth, height, thickness=$thickness) {
  // Edge orientation: thickness in X, depth in Y, height in Z
  echo_material(name, depth, height, thickness);
  color("Red")
    cube([thickness, depth, height]);
}


// Module: left_panel()
// Synopsis: Creates a side panel at the left (leading edge) of the given space.
// Usage:
//   left_panel(name, space, [thickness]);
// Description:
//   Creates a side-oriented panel positioned at the left (leading edge) of the given space.
//   The panel occupies the left side of the space with the specified thickness. The space to
//   the right of the panel is made available through the $free special variable for children modules.
// Arguments:
//   name = Name identifier for the panel
//   space = Space definition as [[x, y, z], [width, depth, height]]
//   ---
//   thickness = Panel thickness in millimeters. Default: $thickness
// Special Variables:
//   Sets $free = [[x, y, z], [width, depth, height]] for the space to the right of the panel
// Example:
//   left_panel("Left DIV", $inside);
module left_panel(name, space, thickness=$thickness) {
  space_pos = space[0];
  space_dim = space[1];

  $free = [[space_pos.x + thickness, space_pos.y, space_pos.z], [space_dim.x - thickness, space_dim.y, space_dim.z]];

  translate(space_pos)
    _side_panel(name, space_dim.y, space_dim.z, thickness);

  children();
}


// Module: right_panel()
// Synopsis: Creates a side panel at the right (trailing edge) of the given space.
// Usage:
//   right_panel(name, space, [thickness]);
// Description:
//   Creates a side-oriented panel positioned at the right (trailing edge) of the given space.
//   The panel occupies the right side of the space with the specified thickness. The space to
//   the left of the panel is made available through the $free special variable for children modules.
// Arguments:
//   name = Name identifier for the panel
//   space = Space definition as [[x, y, z], [width, depth, height]]
//   ---
//   thickness = Panel thickness in millimeters. Default: $thickness
// Special Variables:
//   Sets $free = [[x, y, z], [width, depth, height]] for the space to the left of the panel
// Example:
//   right_panel("Right DIV", $inside);
module right_panel(name, space, thickness=$thickness) {
  space_pos = space[0];
  space_dim = space[1];

  $free = [space_pos, [space_dim.x - thickness, space_dim.y, space_dim.z]];

  translate([space_pos.x + space_dim.x - thickness, space_pos.y, space_pos.z])
    _side_panel(name, space_dim.y, space_dim.z, thickness);

  children();
}


// Module: side_panel()
// Synopsis: Creates a side panel at the left or right based on thickness sign.
// Usage:
//   side_panel(name, space, [thickness]);
// Description:
//   Creates a side panel positioned at either the left (leading edge) or right (trailing edge)
//   of the given space based on the sign of the thickness parameter. Positive thickness creates
//   a left-aligned panel, negative thickness creates a right-aligned panel using the absolute value.
//   This provides a unified interface for both left_panel() and right_panel().
// Arguments:
//   name = Name identifier for the panel
//   space = Space definition as [[x, y, z], [width, depth, height]]
//   ---
//   thickness = Panel thickness in millimeters. Positive: left-aligned, Negative: right-aligned. Default: $thickness
// Special Variables:
//   Sets $free = [[x, y, z], [width, depth, height]] for the space not occupied by the panel
// Example:
//   side_panel("Left", $inside, 10);      // Left-aligned
//   side_panel("Right", $inside, -10);    // Right-aligned
module side_panel(name, space, thickness=$thickness) {
  if (thickness < 0) {
    right_panel(name, space, abs(thickness))
      children();
  } else {
    left_panel(name, space, thickness)
      children();
  }
}
