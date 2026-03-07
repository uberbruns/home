// Section array normalization utilities

include <sum.scad>

$thickness = 0;

// Special section constants
FLEX = ["FLEX", undef, 1];          // Flexible section that fills remaining space (value = proportion weight)
DIV = ["DIV", undef, $thickness];   // Divider section with thickness

// Function: FLEX()
// Synopsis: Creates a flexible section with a specified proportion weight.
// Usage:
//   section = FLEX(weight);
// Description:
//   Creates a FLEX section vector with the specified weight. The weight determines the proportion
//   of remaining space this section will receive relative to other FLEX sections. A weight of 2
//   will receive twice as much space as a weight of 1.
// Arguments:
//   weight = Proportion weight for this flexible section (default: 1)
// Returns:
//   Section vector as ["FLEX", undef, weight]
// Example:
//   FLEX(2)  // Returns: ["FLEX", undef, 2]
//   FLEX()   // Returns: ["FLEX", undef, 1]
function FLEX(weight=1) = ["FLEX", undef, weight];

// Function: _normalized_section_array()
// Synopsis: Normalizes a sections array to a consistent vector format.
// Usage:
//   normalized = _normalized_section_array(sections);
// Description:
//   Takes a sections array and normalizes all elements to a consistent three-element vector format
//   [type, name, value]. Non-vector elements are converted as follows:
//   - String elements become ["DIV", string, $thickness]
//   - Number elements become ["ABS", undef, number]
//   - undef becomes ["FLEX", undef, undef]
//   - Three-element vectors are passed through unchanged
//   - Two-element vectors [name, value] become ["ABS", name, value]
// Arguments:
//   sections = Array of section definitions, each can be:
//              - A string (becomes ["DIV", string, $thickness])
//              - A number (becomes ["ABS", undef, number])
//              - undef (becomes ["FLEX", undef, undef])
//              - A two-element vector [name, value] (becomes ["ABS", name, value])
//              - A three-element vector [type, name, value] (passed through)
// Returns:
//   Array of normalized vectors as [[type, name, value], ...]
// Example:
//   _normalized_section_array(["Panel", 200, DIV, FLEX, ["Drawer", 150]])
//     // Returns: [["DIV", "Panel", $thickness], ["ABS", undef, 200], ["DIV", undef, $thickness], ["FLEX", undef, undef], ["ABS", "Drawer", 150]]
function _normalized_section_array(sections) = [
  for (section = sections)
    section == undef ? ["FLEX", undef, 1] :
    is_string(section) ? ["DIV", section, $thickness] :
    is_num(section) ? ["ABS", undef, section] :
    is_list(section) && len(section) == 2 ? ["ABS", section[0], section[1]] :
    section  // Already a three-element vector
];


// Function: _normalized_absolute_sections_only()
// Synopsis: Resolves all section types to "ABS" with absolute values.
// Usage:
//   resolved = _normalized_absolute_sections_only(sections, space);
// Description:
//   Takes a normalized sections array (with [type, name, value] vectors) and converts all
//   sections to type "ABS" with absolute values. The function calculates the sum of all
//   absolute values, subtracts it from the available space length, and distributes the remaining
//   length among all "FLEX" sections proportionally based on their value (weight). "DIV" sections
//   get their value resolved. FLEX values represent proportion weights - a FLEX with value 2 gets
//   twice as much space as a FLEX with value 1.
// Arguments:
//   sections = Array of section vectors as [[type, name, value], ...] where type is "ABS", "FLEX", or "DIV"
//   space = Space definition as [[x, y, z], [width, depth, height]]
// Returns:
//   Array of section vectors with all types converted to "ABS" as [["ABS", name, value], ...]
// Example:
//   _normalized_absolute_sections_only([["DIV", "Panel", 18], ["FLEX", undef, 1], ["FLEX", undef, 2], ["ABS", "Drawer", 150]], [[0,0,0], [400,300,500]])
//     // Returns: [["ABS", "Panel", 18], ["ABS", undef, 110.67], ["ABS", undef, 221.33], ["ABS", "Drawer", 150]]
function _normalized_absolute_sections_only(sections, space) =
  let(
    space_length = space[1].z,
    // Sum all ABS and DIV values
    defined_lengths = [for (section = sections) if (section[0] == "ABS" || section[0] == "DIV") section[2]],
    // Sum all FLEX weights
    flex_weights = [for (section = sections) if (section[0] == "FLEX") section[2]],
    total_defined = sum(defined_lengths),
    total_flex_weight = sum(flex_weights),
    remaining_length = space_length - total_defined
  )
  [
    for (section = sections)
      section[0] == "FLEX" ? ["ABS", section[1], total_flex_weight > 0 ? (remaining_length * section[2] / total_flex_weight) : 0] :
      section[0] == "DIV" ? ["ABS", section[1], section[2]] :
      section  // Already "ABS"
  ];


// Function: normalized_sections()
// Synopsis: Fully normalizes a sections array by converting elements and resolving all to "ABS" type.
// Usage:
//   normalized = normalized_sections(sections, space);
// Description:
//   Combines _normalized_section_array() and _normalized_absolute_sections_only() to fully normalize
//   a sections array. First converts all elements to [type, name, value] vectors, then resolves
//   all types to "ABS" by distributing the remaining space length evenly among "FLEX" sections.
// Arguments:
//   sections = Array of section definitions (strings, numbers, or vectors)
//   space = Space definition as [[x, y, z], [width, depth, height]]
// Returns:
//   Array of fully normalized section vectors as [["ABS", name, value], ...]
// Example:
//   normalized_sections(["Panel", 200, FLEX, "Drawer"], [[0,0,0], [400,300,500]])
//     // Returns: [["ABS", "Panel", 18], ["ABS", undef, 200], ["ABS", undef, 264], ["ABS", "Drawer", 18]]
function normalized_sections(sections, space) =
  _normalized_absolute_sections_only(_normalized_section_array(sections), space);
