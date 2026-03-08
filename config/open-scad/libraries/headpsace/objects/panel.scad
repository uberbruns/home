// Panel modules for cabinet construction

include <block.scad>
include <../transformations/inset.scad>
include <../transformations/size.scad>
include <../transformations/name.scad>
include <../transformations/paint.scad>
include <../transformations/texture.scad>
include <../transformations/subdivide.scad>
include <../transformations/context.scad>
include <../models/context/context.scad>
include <../models/material/material.scad>
include <../models/section/section.scad>

// Module: panel()
// Synopsis: Creates one or more panels at the specified alignment(s) within the current space.
// Description:
//   Creates panels positioned according to the alignment parameter. Accepts either a single
//   alignment or a list of alignments. When given a list, panels are nested from first to last.
//   Each panel occupies one face of $head with thickness from the context material. The remaining
//   space is made available through $head for children modules.
// Arguments:
//   alignment = Single alignment (LEFT, RIGHT, TOP, BOTTOM, FRONT, BACK) or list of alignments
//   name = Name identifier for the panel. Only valid for single alignment. Default: derived from alignment
module panel(alignment, name, material) {
  if (_is_alignment_list(alignment)) {
    _panel_recursive(alignment, material) children();
  } else {
    _panel(alignment, name, material) children();
  }
}

// Module: _panel()
// Synopsis: Creates a single panel at the specified alignment.
module _panel(alignment, name, material) {
  $parent = $head;
  effective_material = material != undef ? material : context_material(context_current());
  thickness = material_thickness(effective_material);
  effective_name = name != undef ? name : alignment_display_name(alignment);

  if (alignment_is_left(alignment)) _panel_left(thickness, effective_name, effective_material) children();
  else if (alignment_is_right(alignment)) _panel_right(thickness, effective_name, effective_material) children();
  else if (alignment_is_top(alignment)) _panel_top(thickness, effective_name, effective_material) children();
  else if (alignment_is_bottom(alignment)) _panel_bottom(thickness, effective_name, effective_material) children();
  else if (alignment_is_front(alignment)) _panel_front(thickness, effective_name, effective_material) children();
  else if (alignment_is_back(alignment)) _panel_back(thickness, effective_name, effective_material) children();
}

// Module: _panel_left()
// Synopsis: Creates a left-aligned panel.
module _panel_left(thickness, name, material) {
  ctx = context_current();
  if (context_depth(ctx) <= context_render_depth(ctx)) {
    material(material) push_name(name) {
      size(width=thickness, alignment=LEFT) {
        panel_space = $head;
        columns([ABS(material_veneer_front(material), obj=0), FLEX(obj=1), ABS(material_veneer_back(material), obj=0)]) {
          texture(material_veneer_texture(material)) block(echo_enabled=false);
          paint("Red", layer=0) block(echo_space=panel_space);
        }
      }
    }
  }
  inset(left=thickness) increase_depth() children();
}

// Module: _panel_right()
// Synopsis: Creates a right-aligned panel.
module _panel_right(thickness, name, material) {
  ctx = context_current();
  if (context_depth(ctx) <= context_render_depth(ctx)) {
    material(material) push_name(name) {
      size(width=thickness, alignment=RIGHT) {
        panel_space = $head;
        columns([ABS(material_veneer_back(material), obj=0), FLEX(obj=1), ABS(material_veneer_front(material), obj=0)]) {
          texture(material_veneer_texture(material)) block(echo_enabled=false);
          paint("Red", layer=0) block(echo_space=panel_space);
        }
      }
    }
  }
  inset(right=thickness) increase_depth() children();
}

// Module: _panel_top()
// Synopsis: Creates a top-aligned panel.
module _panel_top(thickness, name, material) {
  ctx = context_current();
  if (context_depth(ctx) <= context_render_depth(ctx)) {
    material(material) push_name(name) {
      size(height=thickness, alignment=TOP) {
        panel_space = $head;
        rows([ABS(material_veneer_back(material), obj=0), FLEX(obj=1), ABS(material_veneer_front(material), obj=0)]) {
          texture(material_veneer_texture(material)) block(echo_enabled=false);
          paint("Blue", layer=0) block(echo_space=panel_space);
        }
      }
    }
  }
  inset(top=thickness) increase_depth() children();
}

// Module: _panel_bottom()
// Synopsis: Creates a bottom-aligned panel.
module _panel_bottom(thickness, name, material) {
  ctx = context_current();
  if (context_depth(ctx) <= context_render_depth(ctx)) {
    material(material) push_name(name) {
      size(height=thickness, alignment=BOTTOM) {
        panel_space = $head;
        rows([ABS(material_veneer_front(material), obj=0), FLEX(obj=1), ABS(material_veneer_back(material), obj=0)]) {
          texture(material_veneer_texture(material)) block(echo_enabled=false);
          paint("Blue", layer=0) block(echo_space=panel_space);
        }
      }
    }
  }
  inset(bottom=thickness) increase_depth() children();
}

// Module: _panel_front()
// Synopsis: Creates a front-aligned panel.
module _panel_front(thickness, name, material) {
  ctx = context_current();
  if (context_depth(ctx) <= context_render_depth(ctx)) {
    material(material) push_name(name) {
      size(depth=thickness, alignment=FRONT) {
        panel_space = $head;
        lanes([ABS(material_veneer_front(material), obj=0), FLEX(obj=1), ABS(material_veneer_back(material), obj=0)]) {
          texture(material_veneer_texture(material)) block(echo_enabled=false);
          paint("Green", layer=0) block(echo_space=panel_space);
        }
      }
    }
  }
  inset(front=thickness) increase_depth() children();
}

// Module: _panel_back()
// Synopsis: Creates a back-aligned panel.
module _panel_back(thickness, name, material) {
  ctx = context_current();
  if (context_depth(ctx) <= context_render_depth(ctx)) {
    material(material) push_name(name) {
      size(depth=thickness, alignment=BACK) {
        panel_space = $head;
        lanes([ABS(material_veneer_front(material), obj=0), FLEX(obj=1), ABS(material_veneer_back(material), obj=0)]) {
          texture(material_veneer_texture(material)) block(echo_enabled=false);
          paint("Green", layer=0) block(echo_space=panel_space);
        }
      }
    }
  }
  inset(back=thickness) increase_depth() children();
}

// Module: _panel_recursive()
// Synopsis: Recursively creates panels from a list of alignments.
// Description:
//   Takes a list of alignments and recursively creates nested panels.
//   The first alignment becomes the outermost panel, with remaining
//   alignments nested inside. Children are passed to the innermost panel.
// Arguments:
//   alignments = List of alignment constants
module _panel_recursive(alignments, material) {
  if (len(alignments) == 0) {
    children();
  } else {
    _panel(alignments[0], undef, material) {
      remaining = len(alignments) > 1 ? [for (i = [1:len(alignments)-1]) alignments[i]] : [];
      _panel_recursive(remaining, material) {
        children();
      }
    }
  }
}
