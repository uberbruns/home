// Split modules for dividing spaces along width, depth, or height

include <../models/section/sections_resolved.scad>

// Module: columns()
// Synopsis: Divides a space along the X axis (width).
// Description:
//   Divides a space horizontally into sections along the X axis.
//   Sections are distributed to children based on the obj property of each section,
//   or round-robin if no obj properties are defined.
// Arguments:
//   sections = Sections array for division along X axis
//   space = Space to divide. Default: $head
//   repeat = Number of times to repeat the sections array. Default: 1
//   insert = Sections to place between repetitions. Default: []
module columns(sections, space = $head, repeat = 1, insert = []) {
  repeated_sections = _generate_repeated_sections(sections, repeat, insert);
  effective_map = _generate_effective_map(repeated_sections, $children);
  space_pos = space_position(space);
  space_dim = space_dimension(space);
  effective_sections = sections_resolved(repeated_sections, space_dim.x);
  section_count = len(effective_sections);
  cumulative = function(i) i == 0 ? 0 : cumulative(i - 1) + section_value(effective_sections[i - 1]);
  spaces = [
    for (i = [0:section_count - 1]) [
      [space_pos.x + cumulative(i), space_pos.y, space_pos.z],
      [section_value(effective_sections[i]), space_dim.y, space_dim.z],
    ]
  ];
  for (child_index = [0:$children - 1]) {
    _render_child(spaces, effective_map[child_index]) increase_depth(child_index) children(child_index);
  }
}

// Module: lanes()
// Synopsis: Divides a space along the Y axis (depth).
// Description:
//   Divides a space along the Y axis into sections.
//   Sections are distributed to children based on the obj property of each section,
//   or round-robin if no obj properties are defined.
// Arguments:
//   sections = Sections array for division along Y axis
//   space = Space to divide. Default: $head
//   repeat = Number of times to repeat the sections array. Default: 1
//   insert = Sections to place between repetitions. Default: []
module lanes(sections, space = $head, repeat = 1, insert = []) {
  repeated_sections = _generate_repeated_sections(sections, repeat, insert);
  effective_map = _generate_effective_map(repeated_sections, $children);
  space_pos = space_position(space);
  space_dim = space_dimension(space);
  effective_sections = sections_resolved(repeated_sections, space_dim.y);
  section_count = len(effective_sections);
  cumulative = function(i) i == 0 ? 0 : cumulative(i - 1) + section_value(effective_sections[i - 1]);
  spaces = [
    for (i = [0:section_count - 1]) [
      [space_pos.x, space_pos.y + cumulative(i), space_pos.z],
      [space_dim.x, section_value(effective_sections[i]), space_dim.z],
    ]
  ];
  for (child_index = [0:$children - 1]) {
    _render_child(spaces, effective_map[child_index])increase_depth(child_index) children(child_index);
  }
}

// Module: rows()
// Synopsis: Divides a space along the Z axis (height).
// Description:
//   Divides a space vertically into sections along the Z axis.
//   Sections are distributed to children based on the obj property of each section,
//   or round-robin if no obj properties are defined.
// Arguments:
//   sections = Sections array for division along Z axis
//   space = Space to divide. Default: $head
//   repeat = Number of times to repeat the sections array. Default: 1
//   insert = Sections to place between repetitions. Default: []
module rows(sections, space = $head, repeat = 1, insert = []) {
  repeated_sections = _generate_repeated_sections(sections, repeat, insert);
  effective_map = _generate_effective_map(repeated_sections, $children);
  space_pos = space_position(space);
  space_dim = space_dimension(space);
  effective_sections = sections_resolved(repeated_sections, space_dim.z);
  section_count = len(effective_sections);
  cumulative = function(i) i == 0 ? 0 : cumulative(i - 1) + section_value(effective_sections[i - 1]);
  spaces = [
    for (i = [0:section_count - 1]) [
      [space_pos.x, space_pos.y, space_pos.z + cumulative(i)],
      [space_dim.x, space_dim.y, section_value(effective_sections[i])],
    ]
  ];
  for (child_index = [0:$children - 1]) {
    _render_child(spaces, effective_map[child_index]) increase_depth(child_index) children(child_index);
  }
}

// Function: _generate_repeated_sections()
// Synopsis: Repeats a sections array a specified number of times with optional insert sections.
// Description:
//   Takes a sections array and repeats it the specified number of times.
//   Optionally places insert sections between each repetition.
//   For example, [FLEX()] with repeat=3 becomes [FLEX(), FLEX(), FLEX()].
//   With insert=[DIV()], it becomes [FLEX(), DIV(), FLEX(), DIV(), FLEX()].
// Arguments:
//   sections = Sections array to repeat
//   repeat = Number of times to repeat. Default: 1
//   insert = Sections to place between repetitions. Default: []
// Returns:
//   Repeated sections array with insert sections
function _generate_repeated_sections(sections, repeat = 1, insert = []) =
  [for (r = [0:repeat - 1]) each concat(
    r > 0 ? insert : [],
    sections
  )];

// Function: _generate_effective_map()
// Synopsis: Generates the effective map for distributing sections to children.
// Description:
//   Takes sections and children count, and returns a normalized map distributed
//   across children using round-robin or based on obj properties.
// Arguments:
//   sections = Sections array
//   children_count = Number of children to distribute to
// Returns:
//   List of lists, where each inner list contains section indices for that child
function _generate_effective_map(sections, children_count) =
  _distribute_roundrobin(_generate_map_automatically(sections), children_count);

// Function: _sections_have_object_defined()
// Synopsis: Checks if any section has a defined obj property.
// Description:
//   Returns true if at least one section in the list has an obj property that is not undef.
// Arguments:
//   sections = Sections array
// Returns:
//   Boolean: true if any section has a defined obj, false otherwise
function _sections_have_object_defined(sections) =
  len([for (s = sections) if (section_obj(s) != undef) true]) > 0;

// Function: _sections_max_object_index()
// Synopsis: Returns the highest object index in a list of sections.
// Description:
//   Finds and returns the maximum object index among all sections that have a defined obj property.
// Arguments:
//   sections = Sections array
// Returns:
//   Integer: highest object index, or 0 if no sections have a defined obj
function _sections_max_object_index(sections) =
  let(object_indices = [for (s = sections) if (section_obj(s) != undef) section_obj(s)])
  len(object_indices) > 0 ? max(object_indices) : 0;

// Function: _generate_map_from_object_properties()
// Synopsis: Generates a map based on obj properties of sections.
// Description:
//   Creates a map where each index corresponds to an object index, and the list at that index
//   contains all section indices that have that obj property value.
// Arguments:
//   sections = Sections array
// Returns:
//   List of lists, where each inner list contains section indices for that object index
// Example:
//   For sections [FLEX(obj=1), FLEX(obj=0), FLEX(obj=1)]:
//   _generate_map_from_object_properties returns [[1], [0, 2]]
function _generate_map_from_object_properties(sections) =
  let(
    max_object_index = _sections_max_object_index(sections),
    count = max_object_index + 1
  )
  [
    for (object_index = [0:count - 1])
      [for (section_index = [0:len(sections) - 1])
        if (section_obj(sections[section_index]) == object_index)
          section_index
      ]
  ];

// Function: _generate_map_automatically()
// Synopsis: Generates a map from sections automatically.
// Description:
//   Creates a map based on sections. If any section has a defined obj property,
//   uses _generate_map_from_object. Otherwise, generates sequential indices.
// Arguments:
//   sections = Sections array
// Returns:
//   List of integers or list of lists depending on whether sections have obj properties
function _generate_map_automatically(sections) =
  _sections_have_object_defined(sections)
    ? _generate_map_from_object_properties(sections)
    : _generate_sequential_indices(len(sections));

// Function: _generate_sequential_indices()
// Synopsis: Generates sequential indices from 0 to count-1 as list of lists.
// Description:
//   Creates a list of single-element lists containing sequential integers.
// Arguments:
//   count = Number of indices to generate
// Returns:
//   List of single-element lists from 0 to count-1
// Example:
//   _generate_sequential_indices(3) returns [[0], [1], [2]]
function _generate_sequential_indices(count) = [for (i = [0:count - 1]) [i]];

// Function: _distribute_roundrobin()
// Synopsis: Distributes a list of lists across a target count using round-robin.
// Description:
//   Reduces a list of lists to a specified count by distributing elements from
//   indices that exceed count to earlier indices using modulo arithmetic.
//   Elements at index i are added to the list at index (i % count).
// Arguments:
//   map = List of lists to distribute
//   count = Target number of lists in the result
// Returns:
//   Distributed list of lists with length count
// Example:
//   _distribute_roundrobin([[0], [1], [2], [3], [4]], 2) returns [[0, 2, 4], [1, 3]]
function _distribute_roundrobin(map, count) = [
  for (i = [0:count - 1])
    [for (j = [0:len(map) - 1])
      if (j % count == i)
        for (element = map[j])
          element
    ]
];

// Module: _render_child()
// Synopsis: Renders a child in one or more spaces based on space_indicies.
// Description:
//   Renders the child module for each space index in the space_indicies list.
//   space_indicies is always a list of integers after map processing.
module _render_child(spaces, space_indicies) {
  if (len(space_indicies) > 0) {
    for (selection_index = [0:len(space_indicies) - 1]) {
      space_index = space_indicies[selection_index];
      if (is_num(space_index)) {
        $head = spaces[space_index];
        children();
      } else {
        echo(str("WARNING: split() map contains non-numeric space index: ", space_index));
      }
    }
  }
}
