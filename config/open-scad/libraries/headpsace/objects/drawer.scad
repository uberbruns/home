// Drawer module for creating drawer boxes

include <panel.scad>
include <../transformations/inset.scad>
include <../transformations/name.scad>
include <../transformations/paint.scad>

// Module: drawer()
// Synopsis: Creates a complete drawer box with five panels (front, left, right, floor, back).
// Description:
//   Creates a complete drawer box with all necessary panels.
//   The interior space is made available for children modules.
module drawer() {
  push_name("Drawer") {
    // Front panel - spans full width and height
    paint("LightGray")
      inset(width=2, height=2) panel(FRONT) {

        // Left side panel
        inset(width=40, height=40) panel(LEFT) {

          // Right side panel
          panel(RIGHT) {

            // Floor panel - sits at the bottom
            panel(BOTTOM) {

              // Back panel - at the back, above floor
              panel(BACK)
                children();
            }
          }
        }
      }
  }
}
