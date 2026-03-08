// Cabinet module for creating cabinet boxes

include <panel.scad>
include <../transformations/inset.scad>
include <../transformations/name.scad>

// Module: cabinet()
// Synopsis: Creates a complete cabinet box with five panels (bottom, top, left, right, back).
// Description:
//   Creates a complete cabinet box with all necessary panels.
//   The interior space is made available for children modules.
module cabinet() {
  push_name("Cabinet") {
    // Bottom panel - spans full width and depth
    panel(BOTTOM) {

      // Top panel - spans full width and depth
      panel(TOP) {

        // Left side panel - spans full depth between top and bottom
        panel(LEFT) {

          // Right side panel - spans full depth between top and bottom
          panel(RIGHT) {

            // Back panel - fits between sides
            panel(BACK)
              children();
          }
        }
      }
    }
  }
}
