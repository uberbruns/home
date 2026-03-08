// Module: inset()
// Synopsis: Insets $head and executes children with the inset space.
// Description:
//   Insets a space with relative adjustments. Positive values shrink the space inward.
//   Symmetric parameters (width, depth, height) apply half their value to both sides -
//   width insets left and right by width/2 each, depth insets front and back by depth/2 each,
//   height insets top and bottom by height/2 each. Relative parameters (left, right, front, back,
//   top, bottom) inset the space in specific directions. Positive values shrink the space inward,
//   negative values expand outward.
// Arguments:
//   ---
//   space = Space type. Default: $head
//   width = Symmetric width inset - insets left and right by width/2 each. Positive shrinks. Default: 0
//   depth = Symmetric depth inset - insets front and back by depth/2 each. Positive shrinks. Default: 0
//   height = Symmetric height inset - insets top and bottom by height/2 each. Positive shrinks. Default: 0
//   left = Amount to inset from the left in millimeters. Positive shrinks. Default: 0
//   right = Amount to inset from the right in millimeters. Positive shrinks. Default: 0
//   front = Amount to inset from the front in millimeters. Positive shrinks. Default: 0
//   back = Amount to inset from the back in millimeters. Positive shrinks. Default: 0
//   top = Amount to inset from the top in millimeters. Positive shrinks. Default: 0
//   bottom = Amount to inset from the bottom in millimeters. Positive shrinks. Default: 0
module inset(space=$head, width=0, depth=0, height=0, left=0, right=0, front=0, back=0, top=0, bottom=0) {
  space_pos = space_position(space);
  space_dim = space_dimension(space);

  // Calculate symmetric adjustments (positive values inset)
  half_width = width / 2;
  half_depth = depth / 2;
  half_height = height / 2;

  // Combine symmetric and explicit relative adjustments (positive values inset)
  total_left = left + half_width;
  total_right = right + half_width;
  total_front = front + half_depth;
  total_back = back + half_depth;
  total_top = top + half_height;
  total_bottom = bottom + half_height;

  // Apply relative adjustments (positive values shrink inward)
  new_width = space_dim.x - total_left - total_right;
  new_depth = space_dim.y - total_front - total_back;
  new_height = space_dim.z - total_top - total_bottom;

  $head = space_new(
    x = space_pos.x + total_left,
    y = space_pos.y + total_front,
    z = space_pos.z + total_bottom,
    width = new_width,
    depth = new_depth,
    height = new_height
  );
  children();
}
