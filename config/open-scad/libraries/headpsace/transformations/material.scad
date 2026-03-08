// Material module for setting context material

include <../models/context/context.scad>
include <../models/material/material.scad>
include <context.scad>

// Module: material()
// Synopsis: Sets the context material and executes children.
// Description:
//   Sets the context to contain the given material and executes child modules.
//   This updates the material used for rendering components.
// Arguments:
//   material = Material vector
module material(material) {
  if (material != undef) {
    update(context_material_set(context_current(), material)) children();
  } else {
    children();
  }
}
