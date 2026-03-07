// Module: echo_material()
// Synopsis: Outputs panel dimensions to the console as valid JSON for cut list generation.
// Usage:
//   echo_material(name, dim1, dim2, thickness);
// Description:
//   Prints panel dimensions to the console as valid JSON, suitable for creating cut lists.
//   The dimensions are automatically arranged with the longest dimension first. This module
//   is called internally by panel modules.
// Arguments:
//   name = Panel name identifier
//   dim1 = First dimension in millimeters
//   dim2 = Second dimension in millimeters
//   thickness = Panel thickness in millimeters
// Example:
//   echo_material("Shelf", 600, 400, 18);
//   // Output: {"name":"Shelf","length":600,"width":400,"thickness":18}
module echo_material(name, dim1, dim2, thickness) {
  panel_length = max(dim1, dim2);
  panel_width = min(dim1, dim2);
  echo(str("{\"name\":\"", name, "\",\"length\":", panel_length, ",\"width\":", panel_width, ",\"thickness\":", thickness, "}"));
}
