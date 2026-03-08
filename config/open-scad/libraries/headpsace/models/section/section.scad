// Section factory function and member accessors

include <../context/context.scad>
include <../material/material.scad>

// Function: section_new()
// Synopsis: Creates a section vector from raw_type, value, and obj parameters.
// Description:
//   Constructs a section vector. This is the canonical constructor for creating
//   section vectors programmatically.
// Arguments:
//   raw_type = Section raw_type, either "ABS" or "FLEX()"
//   value = Section value (absolute dimension for "ABS", weight for "FLEX()")
//   obj = Object index to assign to this section. Default: undef
// Returns:
//   Section vector
function section_new(raw_type, value, obj = undef) = [raw_type, value, obj];

// Special section constants

// Function: DIV()
// Synopsis: Creates a divider section with thickness from context material.
// Arguments:
//   obj = Object index to assign to this section. Default: undef
// Returns:
//   Section vector with thickness from the context material
function DIV(obj = undef) = section_new(raw_type="ABS", value=material_thickness(context_material(context_current())), obj=obj);

// Function: FLEX()
// Synopsis: Creates a flexible section with a specified proportion weight.
// Description:
//   Creates a FLEX section vector with the specified weight. The weight determines the proportion
//   of remaining space this section will receive relative to other FLEX sections. A weight of 2
//   will receive twice as much space as a weight of 1.
// Arguments:
//   weight = Proportion weight for this flexible section (default: 1)
//   obj = Object index to assign to this section. Default: undef
// Returns:
//   Section vector
function FLEX(weight=1, obj = undef) = section_new(raw_type="FLEX()", value=weight, obj=obj);

// Function: ABS()
// Synopsis: Creates an absolute section with a specified value.
// Description:
//   Creates an ABS section vector with the specified absolute value. This is useful for
//   explicitly specifying absolute dimensions in section arrays, making the code more readable
//   and consistent with FLEX() usage.
// Arguments:
//   value = Absolute dimension value in millimeters
//   obj = Object index to assign to this section. Default: undef
// Returns:
//   Section vector
function ABS(value, obj = undef) = section_new(raw_type="ABS", value=value, obj=obj);

// Function: section_raw_type()
// Synopsis: Extracts the raw_type from a section vector.
// Description:
//   Returns the raw_type component of a section vector. The raw_type is either "ABS" for absolute
//   dimensions or "FLEX()" for flexible sections.
// Arguments:
//   section = Section vector
// Returns:
//   String representing the section raw_type ("ABS" or "FLEX()")
function section_raw_type(section) = section[0];

// Function: section_value()
// Synopsis: Extracts the value from a section vector.
// Description:
//   Returns the value component of a section vector. For "ABS" sections, this is the
//   absolute dimension in millimeters. For "FLEX()" sections, this is the proportion weight.
// Arguments:
//   section = Section vector
// Returns:
//   Numeric value (dimension for "ABS", weight for "FLEX()")
function section_value(section) = section[1];

// Function: section_obj()
// Synopsis: Extracts the object index from a section vector.
// Description:
//   Returns the object index component of a section vector. This index specifies which
//   child object should be rendered in this section.
// Arguments:
//   section = Section vector
// Returns:
//   Object index (integer) or undef if not set
function section_obj(section) = section[2];

// Function: section_is_abs()
// Synopsis: Checks if a section is an absolute section.
// Arguments:
//   section = Section vector
// Returns:
//   Boolean: true if section is raw_type "ABS", false otherwise
function section_is_abs(section) = section_raw_type(section) == "ABS";

// Function: section_is_flex()
// Synopsis: Checks if a section is a flexible section.
// Arguments:
//   section = Section vector
// Returns:
//   Boolean: true if section is raw_type "FLEX()", false otherwise
function section_is_flex(section) = section_raw_type(section) == "FLEX()";
