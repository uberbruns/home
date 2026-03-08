// Alignment factory function and member accessors

// Function: alignment_new()
// Synopsis: Creates an alignment vector from raw_type and display_name parameters.
// Description:
//   Constructs an alignment vector. This is the canonical
//   constructor for creating alignment vectors programmatically.
// Arguments:
//   raw_type = Alignment raw_type, one of "LEFT", "RIGHT", "TOP", "BOTTOM", "FRONT", "BACK"
//   display_name = Human-readable name for the alignment
// Returns:
//   Alignment vector
function alignment_new(raw_type, display_name) = [raw_type, display_name];

// Alignment constants
LEFT = alignment_new(raw_type="LEFT", display_name="Left");
RIGHT = alignment_new(raw_type="RIGHT", display_name="Right");
TOP = alignment_new(raw_type="TOP", display_name="Top");
BOTTOM = alignment_new(raw_type="BOTTOM", display_name="Bottom");
FRONT = alignment_new(raw_type="FRONT", display_name="Front");
BACK = alignment_new(raw_type="BACK", display_name="Back");

// Function: alignment_raw_type()
// Synopsis: Extracts the raw_type from an alignment vector.
// Description:
//   Returns the raw_type component of an alignment vector.
// Arguments:
//   alignment = Alignment vector
// Returns:
//   String representing the alignment raw_type
function alignment_raw_type(alignment) = alignment[0];

// Function: alignment_display_name()
// Synopsis: Extracts the display_name from an alignment vector.
// Description:
//   Returns the display_name component of an alignment vector.
// Arguments:
//   alignment = Alignment vector
// Returns:
//   String representing the human-readable alignment name
function alignment_display_name(alignment) = alignment[1];

// Function: alignment_is_left()
// Synopsis: Checks if an alignment is LEFT or if LEFT is in a list of alignments.
// Arguments:
//   alignment_or_list = Alignment vector [raw_type] or list of alignment vectors
// Returns:
//   Boolean: true if alignment is LEFT or if LEFT is present in the list
function alignment_is_left(alignment_or_list) =
  _alignment_matches(alignment_or_list, "LEFT");

// Function: alignment_is_right()
// Synopsis: Checks if an alignment is RIGHT or if RIGHT is in a list of alignments.
// Arguments:
//   alignment_or_list = Alignment vector [raw_type] or list of alignment vectors
// Returns:
//   Boolean: true if alignment is RIGHT or if RIGHT is present in the list
function alignment_is_right(alignment_or_list) =
  _alignment_matches(alignment_or_list, "RIGHT");

// Function: alignment_is_top()
// Synopsis: Checks if an alignment is TOP or if TOP is in a list of alignments.
// Arguments:
//   alignment_or_list = Alignment vector [raw_type] or list of alignment vectors
// Returns:
//   Boolean: true if alignment is TOP or if TOP is present in the list
function alignment_is_top(alignment_or_list) =
  _alignment_matches(alignment_or_list, "TOP");

// Function: alignment_is_bottom()
// Synopsis: Checks if an alignment is BOTTOM or if BOTTOM is in a list of alignments.
// Arguments:
//   alignment_or_list = Alignment vector [raw_type] or list of alignment vectors
// Returns:
//   Boolean: true if alignment is BOTTOM or if BOTTOM is present in the list
function alignment_is_bottom(alignment_or_list) =
  _alignment_matches(alignment_or_list, "BOTTOM");

// Function: alignment_is_front()
// Synopsis: Checks if an alignment is FRONT or if FRONT is in a list of alignments.
// Arguments:
//   alignment_or_list = Alignment vector [raw_type] or list of alignment vectors
// Returns:
//   Boolean: true if alignment is FRONT or if FRONT is present in the list
function alignment_is_front(alignment_or_list) =
  _alignment_matches(alignment_or_list, "FRONT");

// Function: alignment_is_back()
// Synopsis: Checks if an alignment is BACK or if BACK is in a list of alignments.
// Arguments:
//   alignment_or_list = Alignment vector [raw_type] or list of alignment vectors
// Returns:
//   Boolean: true if alignment is BACK or if BACK is present in the list
function alignment_is_back(alignment_or_list) =
  _alignment_matches(alignment_or_list, "BACK");

// Function: _alignment_matches()
// Synopsis: Helper to check if an alignment matches or is in a list.
function _alignment_matches(alignment_or_list, target_type) =
  _is_alignment_list(alignment_or_list)
    ? _list_contains_alignment(alignment_or_list, target_type)
    : alignment_raw_type(alignment_or_list) == target_type;

// Function: _is_alignment_list()
// Synopsis: Checks if value is a list of alignments.
function _is_alignment_list(value) =
  is_list(value) && len(value) > 0 && is_list(value[0]);

// Function: _list_contains_alignment()
// Synopsis: Checks if a list contains an alignment with the given type.
function _list_contains_alignment(list, target_type) =
  len([for (alignment = list) if (alignment_raw_type(alignment) == target_type) 1]) > 0;
