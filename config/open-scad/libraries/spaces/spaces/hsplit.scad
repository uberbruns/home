// Horizontal split modules for dividing spaces

include <../objects/panel.scad>
include <../objects/block.scad>
include <../support/section.scad>


// Module: hsplit_evenly()
// Synopsis: Divides a space into multiple equal-width sections with vertical DIV panels.
// Usage:
//   hsplit_evenly(name, count, space, [thickness]);
// Description:
//   Creates multiple vertical side panels to divide a space into the specified number of
//   equal-width horizontal sections. The available width is automatically distributed evenly
//   across all sections, accounting for panel thickness. The module sets the special variable
//   $spaces containing an array of all created section spaces and updates $path for hierarchical
//   naming. Each panel is numbered sequentially starting from 1.
// Arguments:
//   name = Base name identifier for the horizontal section divisions
//   count = Number of sections to create
//   space = Space definition as [[x, y, z], [width, depth, height]]
//   ---
//   thickness = Panel thickness in millimeters. Default: $thickness
// Special Variables:
//   Sets $spaces = Array of section spaces as [[[x, y, z], [width, depth, height]], ...]
// Example:
//   hsplit_evenly("Shelves", 3, $inside)
//     children();
module hsplit_evenly(name, count, space, thickness=$thickness) {
  space_pos = space[0];
  space_dim = space[1];


  panel_count = count - 1;
  total_panel_thickness = panel_count * thickness;
  available_width = space_dim.x - total_panel_thickness;
  section_width = available_width / count;

  $spaces = [
    for (i = [0:count-1])
      [[space_pos.x + i * (section_width + thickness), space_pos.y, space_pos.z],
       [section_width, space_dim.y, space_dim.z]]
  ];

  for (i = [0:panel_count-1]) {
    color("LightSalmon")
      translate([space_pos.x + (i + 1) * section_width + i * thickness, space_pos.y, space_pos.z])
        _side_panel(str(name, " ", i + 1), space_dim.y, space_dim.z, thickness);
  }

  children();
}


// Module: hsplit_sections()
// Synopsis: Divides a space into sections with specified widths.
// Usage:
//   hsplit_sections(sections, space);
// Description:
//   Creates an array of section spaces with specified widths arranged horizontally.
//   The sections array can contain strings, numbers, or [name, width] vectors:
//   - String elements become [string, $thickness]
//   - Number elements become [undef, number]
//   - Vector elements [name, width] are used as-is, where width can be undef
//   Undefined widths are resolved by distributing remaining space evenly.
//   The module sets the special variable $spaces containing an array of all created section spaces.
//   No panels are rendered.
// Arguments:
//   sections = Array of section definitions (strings, numbers, or [name, width] vectors)
//   space = Space definition as [[x, y, z], [width, depth, height]]
// Special Variables:
//   Sets $spaces = Array of section spaces as [[[x, y, z], [width, depth, height]], ...]
// Example:
//   hsplit_sections([200, "Panel", [undef, undef], 150], $inside)
//     children();
module hsplit_sections(sections, space) {
  space_pos = space[0];
  space_dim = space[1];

  // Create a modified space for normalized_sections that uses x dimension as the length
  space_for_norm = [[space_pos.x, space_pos.y, space_pos.z], [space_dim.x, space_dim.y, space_dim.x]];
  norm_sections = normalized_sections(sections, space_for_norm);
  count = len(norm_sections);

  // Calculate cumulative x positions for each section
  // Each section starts at the previous x + previous width
  function cumulative_x(i) =
    i == 0 ? 0 :
    cumulative_x(i - 1) + norm_sections[i - 1][2];

  $spaces = [
    for (i = [0:count-1])
      [[space_pos.x + cumulative_x(i), space_pos.y, space_pos.z],
       [norm_sections[i][2], space_dim.y, space_dim.z]]
  ];

  // Render blocks for named sections
  for (i = [0:count-1]) {
    if (norm_sections[i][1] != undef) {
      color("LightSalmon")
        block(norm_sections[i][1], $spaces[i]);
    }
  }

  children();
}


// Module: hsplit()
// Synopsis: Smart alias that calls hsplit_evenly() or hsplit_sections() based on parameter type.
// Usage:
//   hsplit(name, count_or_sections, space, [thickness]);
// Description:
//   Intelligent alias that dispatches to the appropriate hsplit module based on the type of the
//   second parameter:
//   - If the parameter is a number, calls hsplit_evenly(name, count, space, thickness)
//   - If the parameter is an array, calls hsplit_sections(name, sections, space)
//   This provides a unified interface for both equal and custom width divisions.
// Arguments:
//   name = Base name identifier for the horizontal section divisions
//   count_or_sections = Either a number (count of equal sections) or array (section widths/definitions)
//   space = Space definition as [[x, y, z], [width, depth, height]]
//   ---
//   thickness = Panel thickness in millimeters. Default: $thickness (only used with count)
// Special Variables:
//   Sets $spaces = Array of section spaces as [[[x, y, z], [width, depth, height]], ...]
// Examples:
//   hsplit("Columns", 3, $inside)           // Creates 3 equal sections
//     children();
//   hsplit("Columns", [200, 150, 300], $inside)  // Creates sections with specific widths
//     children();
module hsplit(name, count_or_sections, space, thickness=$thickness) {
  if (is_list(count_or_sections)) {
    hsplit_sections(count_or_sections, space)
      children();
  } else {
    hsplit_evenly(name, count_or_sections, space, thickness)
      children();
  }
}
