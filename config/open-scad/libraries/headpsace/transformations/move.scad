// Module: move()
// Synopsis: Moves $head and executes children with the moved space.
// Description:
//   Moves a space by adjusting its position based on directional offsets.
//   Positive values for left/front/bottom move in those directions (decreasing x/y/z).
//   Positive values for right/back/top move in those directions (increasing x/y/z).
//   The dimensions of the space remain unchanged.
// Arguments:
//   ---
//   space = Space type. Default: $head
//   left = Amount to move left (negative X direction) in millimeters. Default: 0
//   right = Amount to move right (positive X direction) in millimeters. Default: 0
//   front = Amount to move forward (negative Y direction) in millimeters. Default: 0
//   back = Amount to move backward (positive Y direction) in millimeters. Default: 0
//   bottom = Amount to move down (negative Z direction) in millimeters. Default: 0
//   top = Amount to move up (positive Z direction) in millimeters. Default: 0
module move(space=$head, left=0, right=0, front=0, back=0, bottom=0, top=0) {
  space_pos = space_position(space);
  space_dim = space_dimension(space);

  // Calculate net movement in each axis
  x_offset = right - left;
  y_offset = back - front;
  z_offset = top - bottom;

  // Apply offsets to position
  $head = space_new(
    x = space_pos.x + x_offset,
    y = space_pos.y + y_offset,
    z = space_pos.z + z_offset,
    width = space_dim.x,
    depth = space_dim.y,
    height = space_dim.z
  );
  children();
}
