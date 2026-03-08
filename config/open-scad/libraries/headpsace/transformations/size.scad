// Module: size()
// Synopsis: Sets absolute dimensions of $head and executes children with the sized space.
// Description:
//   Sets absolute dimensions for a space. Alignment determines positioning on each axis.
//   If no alignment is specified for an axis, the resized space is centered on that axis.
//   Undefined dimension parameters keep the original dimension unchanged.
// Arguments:
//   ---
//   space = Space type. Default: $head
//   width = Absolute width in millimeters. Default: undef (keep original)
//   depth = Absolute depth in millimeters. Default: undef (keep original)
//   height = Absolute height in millimeters. Default: undef (keep original)
//   alignment = Alignment or list of alignments (LEFT, RIGHT, FRONT, BACK, TOP, BOTTOM). Default: [] (center all axes)
module size(space=$head, width=undef, depth=undef, height=undef, alignment=[]) {
  space_pos = space_position(space);
  space_dim = space_dimension(space);

  // Apply absolute dimensions
  final_width = width == undef ? space_dim.x : width;
  final_depth = depth == undef ? space_dim.y : depth;
  final_height = height == undef ? space_dim.z : height;

  // Calculate position offsets based on alignment
  // Width axis: LEFT (0), CENTER (default), or RIGHT
  width_offset =
    alignment_is_left(alignment) ? 0 :
    alignment_is_right(alignment) ? space_dim.x - final_width :
    (space_dim.x - final_width) / 2;  // Center by default

  // Depth axis: FRONT (0), CENTER (default), or BACK
  depth_offset =
    alignment_is_front(alignment) ? 0 :
    alignment_is_back(alignment) ? space_dim.y - final_depth :
    (space_dim.y - final_depth) / 2;  // Center by default

  // Height axis: BOTTOM (0), CENTER (default), or TOP
  height_offset =
    alignment_is_bottom(alignment) ? 0 :
    alignment_is_top(alignment) ? space_dim.z - final_height :
    (space_dim.z - final_height) / 2;  // Center by default

  // Apply position offsets
  $head = space_new(
    x = space_pos.x + width_offset,
    y = space_pos.y + depth_offset,
    z = space_pos.z + height_offset,
    width = final_width,
    depth = final_depth,
    height = final_height
  );
  children();
}
