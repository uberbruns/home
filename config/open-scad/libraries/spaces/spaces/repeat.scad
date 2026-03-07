// Module: repeat()
// Synopsis: Iterates over an array of spaces, executing child modules for each.
// Usage:
//   repeat(spaces) { children(); }
// Description:
//   Executes the child modules once for each space in the given array. For each iteration,
//   sets the special variable $space to the current space definition. This module is useful
//   for applying the same operations to multiple spaces created by modules like hsplit().
// Arguments:
//   spaces = Array of space definitions [[[x, y, z], [width, depth, height]], ...]
// Special Variables:
//   Sets $space = Current space definition for this iteration
// Example:
//   repeat($spaces) {
//     drawer("Drawer", $space);
//   }
module repeat(spaces) {
  for (i = [0:len(spaces)-1]) {
    $space = spaces[i];
    children();
  }
}
