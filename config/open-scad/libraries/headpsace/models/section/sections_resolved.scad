// Functions around sections

include <section.scad>

// Function: sections_resolved()
// Synopsis: Resolves section array to absolute values.
// Description:
//   Converts a sections array to absolute values, distributing remaining space
//   among FLEX() sections proportionally by weight.
// Arguments:
//   sections = Array of section definitions (numbers or vectors)
//   length = Total length to distribute among sections
// Returns:
//   Array of fully resolved section vectors as [["ABS", value], ...]
function sections_resolved(sections, length) =
  _sections_resolved(_sections_normalized(sections), length);

// Function: _sections_normalized()
// Synopsis: Normalizes sections to consistent vector format.
function _sections_normalized(sections) = [
  for (section = sections)
    is_num(section) ? ABS(section) :
    section  // Already a two-element vector
];

// Function: _sections_resolved()
// Synopsis: Resolves FLEX() sections to absolute values.
function _sections_resolved(sections, length) =
  let(
    // Sum all ABS values
    defined_lengths = [for (section = sections) if (section_is_abs(section)) section_value(section)],
    // Sum all FLEX() weights
    flex_weights = [for (section = sections) if (section_is_flex(section)) section_value(section)],
    total_defined = _sum(defined_lengths),
    total_flex_weight = _sum(flex_weights),
    remaining_length = length - total_defined
  )
  [
    for (section = sections)
      section_is_flex(section) ? ABS(total_flex_weight > 0 ? (remaining_length * section_value(section) / total_flex_weight) : 0) :
      section  // Already "ABS"
  ];

// Helper function to sum array elements
function _sum(arr) =
  len(arr) == 0 ? 0 :
  len(arr) == 1 ? (arr[0] == undef ? 0 : arr[0]) :
  (arr[0] == undef ? 0 : arr[0]) + _sum([for (i = [1:len(arr)-1]) arr[i]]);
