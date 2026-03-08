// Fill module for setting the $head variable

// Module: in()
// Synopsis: Sets $head to a custom space vector.
// Description:
//   Sets the $head variable to a custom space vector and renders children within that space.
//   This is useful for explicitly setting a working space for children modules.
// Arguments:
//   space = Space type
module in(space=$head) {
  $head = space;
  children();
}
