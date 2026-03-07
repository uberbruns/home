// Vertical split modules for dividing spaces

include <../objects/panel.scad>
include <../objects/block.scad>
include <../support/section.scad>


// Module: vsplit_evenly()
// Synopsis: Divides a space into multiple equal-height sections with horizontal DIV panels.
// Usage:
//   vsplit_evenly(name, count, space, [thickness]);
// Description:
//   Creates multiple horizontal flat panels to divide a space into the specified number of
//   equal-height vertical sections. The available height is automatically distributed evenly
//   across all sections, accounting for panel thickness. The module sets the special variable
//   $spaces containing an array of all created section spaces and updates $path for hierarchical
//   naming. Each panel is numbered sequentially starting from 1.
// Arguments:
//   name = Base name identifier for the vertical section divisions
//   count = Number of sections to create
//   space = Space definition as [[x, y, z], [width, depth, height]]
//   ---
//   thickness = Panel thickness in millimeters. Default: $thickness
// Special Variables:
//   Sets $spaces = Array of section spaces as [[[x, y, z], [width, depth, height]], ...]
// Example:
//   vsplit_evenly("Drawers", 3, $inside)
//     children();
module vsplit_evenly(name, count, space, thickness=$thickness) {
  space_pos = space[0];
  space_dim = space[1];


  panel_count = count - 1;
  total_panel_thickness = panel_count * thickness;
  available_height = space_dim.z - total_panel_thickness;
  section_height = available_height / count;

  $spaces = [
    for (i = [0:count-1])
      [[space_pos.x, space_pos.y, space_pos.z + i * (section_height + thickness)],
       [space_dim.x, space_dim.y, section_height]]
  ];

  for (i = [0:panel_count-1]) {
    color("Wheat")
      translate([space_pos.x, space_pos.y, space_pos.z + (i + 1) * section_height + i * thickness])
        _flat_panel(str(name, " ", i + 1), space_dim.x, space_dim.y, thickness);
  }

  children();
}


// Module: vsplit_sections()
// Synopsis: Divides a space into sections with specified heights.
// Usage:
//   vsplit_sections(sections, space);
// Description:
//   Creates an array of section spaces with specified heights stacked vertically.
//   The sections array can contain strings, numbers, or [name, height] vectors:
//   - String elements become [string, $thickness]
//   - Number elements become [undef, number]
//   - Vector elements [name, height] are used as-is, where height can be undef
//   Undefined heights are resolved by distributing remaining space evenly.
//   The module sets the special variable $spaces containing an array of all created section spaces.
//   No panels are rendered.
// Arguments:
//   sections = Array of section definitions (strings, numbers, or [name, height] vectors)
//   space = Space definition as [[x, y, z], [width, depth, height]]
// Special Variables:
//   Sets $spaces = Array of section spaces as [[[x, y, z], [width, depth, height]], ...]
// Example:
//   vsplit_sections([200, "Panel", [undef, undef], 150], $inside)
//     children();
module vsplit_sections(sections, space) {
  space_pos = space[0];
  space_dim = space[1];

  norm_sections = normalized_sections(sections, space);
  count = len(norm_sections);

  // Calculate cumulative z positions for each section
  // Each section starts at the previous z + previous height
  function cumulative_z(i) =
    i == 0 ? 0 :
    cumulative_z(i - 1) + norm_sections[i - 1][2];

  $spaces = [
    for (i = [0:count-1])
      [[space_pos.x, space_pos.y, space_pos.z + cumulative_z(i)],
       [space_dim.x, space_dim.y, norm_sections[i][2]]]
  ];

  // Render blocks for named sections
  for (i = [0:count-1]) {
    if (norm_sections[i][1] != undef) {
      color("Wheat")
        block(norm_sections[i][1], $spaces[i]);
    }
  }

  children();
}


// Module: vsplit()
// Synopsis: Smart alias that calls vsplit_evenly() or vsplit_sections() based on parameter type.
// Usage:
//   vsplit(name, count_or_sections, space, [thickness]);
// Description:
//   Intelligent alias that dispatches to the appropriate vsplit module based on the type of the
//   second parameter:
//   - If the parameter is a number, calls vsplit_evenly(name, count, space, thickness)
//   - If the parameter is an array, calls vsplit_sections(name, sections, space)
//   This provides a unified interface for both equal and custom height divisions.
// Arguments:
//   name = Base name identifier for the vertical section divisions
//   count_or_sections = Either a number (count of equal sections) or array (section heights/definitions)
//   space = Space definition as [[x, y, z], [width, depth, height]]
//   ---
//   thickness = Panel thickness in millimeters. Default: $thickness (only used with count)
// Special Variables:
//   Sets $spaces = Array of section spaces as [[[x, y, z], [width, depth, height]], ...]
// Examples:
//   vsplit("Drawers", 3, $inside)           // Creates 3 equal sections
//     children();
//   vsplit("Drawers", [200, 150, 300], $inside)  // Creates sections with specific heights
//     children();
module vsplit(name, count_or_sections, space, thickness=$thickness) {
  if (is_list(count_or_sections)) {
    vsplit_sections(count_or_sections, space)
      children();
  } else {
    vsplit_evenly(name, count_or_sections, space, thickness)
      children();
  }
}
