// Headspace Library - Single entry point for all space construction modules
// This file includes all modules needed for parametric space construction

// Models
include <models/alignment/alignment.scad>
include <models/context/context.scad>
include <models/material/material.scad>
include <models/section/section.scad>
include <models/section/sections_resolved.scad>
include <models/space/space_union.scad>
include <models/space/space.scad>
include <models/texture/texture.scad>

// Objects
include <objects/block.scad>
include <objects/cabinet.scad>
include <objects/door.scad>
include <objects/drawer.scad>
include <objects/panel.scad>

// Transformations
include <transformations/context.scad>
include <transformations/in.scad>
include <transformations/inset.scad>
include <transformations/material.scad>
include <transformations/move.scad>
include <transformations/name.scad>
include <transformations/paint.scad>
include <transformations/size.scad>
include <transformations/subdivide.scad>