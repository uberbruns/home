// Function: resized()
// Synopsis: Resizes a space with absolute dimensions or relative adjustments.
// Usage:
//   new_space = resized(space, [width], [depth], [height], [left], [right], [front], [back], [top], [bottom]);
// Description:
//   Creates a new space definition by either setting absolute dimensions or applying relative
//   adjustments. Absolute parameters (width, depth, height) set exact dimensions. Positive values
//   keep the leading edge (left/front/bottom), negative values use the absolute value but align
//   to the trailing edge (right/back/top). Relative parameters (left, right, front, back, top, bottom)
//   expand or contract the space in specific directions. When expanding left/front/bottom, the position
//   is adjusted accordingly. Relative adjustments are applied after absolute dimensions.
// Arguments:
//   space = Space definition as [[x, y, z], [width, depth, height]]
//   ---
//   width = Absolute width in millimeters. Positive: align left, Negative: align right. Default: undef (keep original)
//   depth = Absolute depth in millimeters. Positive: align front, Negative: align back. Default: undef (keep original)
//   height = Absolute height in millimeters. Positive: align bottom, Negative: align top. Default: undef (keep original)
//   left = Amount to expand to the left in millimeters. Default: 0
//   right = Amount to expand to the right in millimeters. Default: 0
//   front = Amount to expand to the front in millimeters. Default: 0
//   back = Amount to expand to the back in millimeters. Default: 0
//   top = Amount to expand to the top in millimeters. Default: 0
//   bottom = Amount to expand to the bottom in millimeters. Default: 0
// Returns:
//   New space definition as [[x, y, z], [width, depth, height]]
// Example:
//   // Absolute sizing, align to leading edge
//   adjusted = resized($inside, height=500);
//   // Absolute sizing, align to trailing edge
//   top_aligned = resized($inside, height=-500);
//   // Relative expansion
//   larger = resized($inside, left=10, right=5, top=20);
//   // Combined
//   mixed = resized($inside, height=500, left=10, right=5);
function resized(space, width=undef, depth=undef, height=undef, left=0, right=0, front=0, back=0, top=0, bottom=0) =
  let(
    space_pos = space[0],
    space_dim = space[1],
    // First apply absolute dimensions and handle alignment
    abs_width = width == undef ? space_dim.x : abs(width),
    abs_depth = depth == undef ? space_dim.y : abs(depth),
    abs_height = height == undef ? space_dim.z : abs(height),
    // Calculate position offsets for trailing edge alignment
    width_offset = (width != undef && width < 0) ? space_dim.x - abs_width : 0,
    depth_offset = (depth != undef && depth < 0) ? space_dim.y - abs_depth : 0,
    height_offset = (height != undef && height < 0) ? space_dim.z - abs_height : 0,
    // Apply position offsets for absolute dimensions
    base_pos = [
      space_pos.x + width_offset,
      space_pos.y + depth_offset,
      space_pos.z + height_offset
    ],
    // Then apply relative adjustments
    new_width = abs_width + left + right,
    new_depth = abs_depth + front + back,
    new_height = abs_height + top + bottom,
    new_pos = [
      base_pos.x - left,
      base_pos.y - front,
      base_pos.z - bottom
    ],
    new_dim = [new_width, new_depth, new_height]
  )
  [new_pos, new_dim];
