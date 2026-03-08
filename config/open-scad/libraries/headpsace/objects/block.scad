// Block module for filling spaces with solid cubes

include <../models/space/space.scad>
include <../models/context/context.scad>
include <../models/texture/texture.scad>
include <../models/material/material.scad>

// Module: block()
// Synopsis: Creates a cube that fills $head.
// Description:
//   Creates a solid cube that completely fills $head. This is useful for
//   visualizing interior volumes or creating placeholder objects that occupy a space.
//   For material calculation, the dimensions are sorted: longest side becomes length,
//   middle dimension becomes width, and shortest side becomes thickness.
//   The color is read from the context texture (paint if defined, otherwise material texture).
// Arguments:
//   echo_enabled = Whether to echo material information. Default: true
//   echo_space = Space to use for echo output. Default: undef (uses $head)
module block(echo_enabled = true, echo_space = undef) {
  space_dim = space_dimension($head);

  if (space_dim.x > 0 && space_dim.y > 0 && space_dim.z > 0) {
    if (echo_enabled) {
      _block_echo(echo_space != undef ? echo_space : $head);
    }

    // Read texture from context (falls back from paint to material texture)
    texture_value = context_texture(context_current());

    color(texture_color(texture_value), texture_alpha(texture_value))
      translate(space_position($head))
        cube(space_dimension($head));
  }
}

// Module: _block_echo()
// Synopsis: Echoes material information with sorted dimensions.
// Arguments:
//   space = Space to use for dimension calculation
module _block_echo(space) {
  space_dim = space_dimension(space);

  // Sort dimensions: shortest = thickness, middle = width, longest = length
  sorted_dims = _quicksort([space_dim.x, space_dim.y, space_dim.z]);

  thickness = sorted_dims[0];
  width = sorted_dims[1];
  length = sorted_dims[2];

  // Build fully qualified name with context
  full_name = context_name(context_current());

  // Get material name and depth from context
  mat = context_material(context_current());
  mat_name = material_name(mat);
  depth = context_depth(context_current());

  echo(str("{\"name\":\"", full_name, "\",\"material\":\"", mat_name, "\",\"depth\":", depth, ",\"length\":", length, ",\"width\":", width, ",\"thickness\":", thickness, "}"));
}

// Helper function to sort an array of numbers in ascending order
function _quicksort(arr) = !(len(arr)>0) ? [] : let(
    pivot   = arr[floor(len(arr)/2)],
    lesser  = [ for (y = arr) if (y  < pivot) y ],
    equal   = [ for (y = arr) if (y == pivot) y ],
    greater = [ for (y = arr) if (y  > pivot) y ]
) concat(
    _quicksort(lesser), equal, _quicksort(greater)
);
