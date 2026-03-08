// Door module for cabinet fronts

include <panel.scad>
include <../transformations/inset.scad>
include <../models/section/section.scad>
include <../transformations/subdivide.scad>
include <../transformations/paint.scad>
include <../models/context/context.scad>
include <../models/material/material.scad>


// Module: door()
// Synopsis: Creates a cabinet door panel with tolerance gaps on all sides.
// Description:
//   Creates a door panel with specified tolerance gaps around all edges.
//   The space behind the door is made available for children modules.
// Arguments:
//   ---
//   tolerance = Gap around door edges in millimeters. Default: 1
module door(tolerance=1) {
  thickness = material_thickness(context_material(context_current()));
  split(depth=[ABS(thickness), FLEX()]) {
    // Door section - inset for tolerance and create panel
    inset(width=2*tolerance, height=2*tolerance) {
      #paint("SandyBrown")
        panel(FRONT);
    }

    // Interior section - pass to children
    children();
  }
}
