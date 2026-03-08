// Material model for thickness and texture representation

include <../texture/texture.scad>

// Function: material_new()
// Synopsis: Creates a material vector from name, thickness and texture values.
// Description:
//   Constructs a material vector. This is the canonical constructor for creating material vectors programmatically.
// Arguments:
//   name = Name identifier string
//   thickness = Thickness value in millimeters
//   texture = Texture vector. Default: undef
//   veneer_texture = Veneer texture vector. Default: undef
//   veneer_front = Front veneer thickness value in millimeters. Default: 0
//   veneer_back = Back veneer thickness value in millimeters. Default: 0
// Returns:
//   Material vector
function material_new(name, thickness, texture = undef, veneer_texture = undef, veneer_front = 0, veneer_back = 0) =
  [name, thickness, texture, veneer_texture, veneer_front, veneer_back];

// Function: material_name()
// Synopsis: Extracts the name from a material vector.
// Arguments:
//   material = Material vector
// Returns:
//   Name identifier string
function material_name(material) = material[0];

// Function: material_thickness()
// Synopsis: Extracts the thickness value from a material vector.
// Arguments:
//   material = Material vector
// Returns:
//   Thickness value in millimeters
function material_thickness(material) = material[1];

// Function: material_texture()
// Synopsis: Extracts the texture from a material vector.
// Arguments:
//   material = Material vector
// Returns:
//   Texture vector (may be undefined)
function material_texture(material) = material[2];

// Function: material_veneer_texture()
// Synopsis: Extracts the veneer texture from a material vector.
// Arguments:
//   material = Material vector
// Returns:
//   Veneer texture vector (may be undefined)
function material_veneer_texture(material) = material[3];

// Function: material_veneer_front()
// Synopsis: Extracts the front veneer thickness value from a material vector.
// Arguments:
//   material = Material vector
// Returns:
//   Front veneer thickness value in millimeters, or 0 if undefined
function material_veneer_front(material) = material[4] == undef ? 0 : material[4];

// Function: material_veneer_back()
// Synopsis: Extracts the back veneer thickness value from a material vector.
// Arguments:
//   material = Material vector
// Returns:
//   Back veneer thickness value in millimeters, or 0 if undefined
function material_veneer_back(material) = material[5] == undef ? 0 : material[5];

// Function: material_veneer_texture_set()
// Synopsis: Sets the veneer texture in a material vector.
// Arguments:
//   material = Material vector
//   veneer_texture = New veneer texture vector
// Returns:
//   New material vector with updated veneer texture
function material_veneer_texture_set(material, veneer_texture) =
  material_new(
    material_name(material),
    material_thickness(material),
    material_texture(material),
    veneer_texture,
    material_veneer_front(material),
    material_veneer_back(material)
  );

// Function: material_veneer_front_set()
// Synopsis: Sets the front veneer thickness in a material vector.
// Arguments:
//   material = Material vector
//   veneer_front = New front veneer thickness value in millimeters
// Returns:
//   New material vector with updated front veneer thickness
function material_veneer_front_set(material, veneer_front) =
  material_new(
    material_name(material),
    material_thickness(material),
    material_texture(material),
    material_veneer_texture(material),
    veneer_front,
    material_veneer_back(material)
  );

// Function: material_veneer_back_set()
// Synopsis: Sets the back veneer thickness in a material vector.
// Arguments:
//   material = Material vector
//   veneer_back = New back veneer thickness value in millimeters
// Returns:
//   New material vector with updated back veneer thickness
function material_veneer_back_set(material, veneer_back) =
  material_new(
    material_name(material),
    material_thickness(material),
    material_texture(material),
    material_veneer_texture(material),
    material_veneer_front(material),
    veneer_back
  );

// Function: MDF()
// Synopsis: Creates an MDF material with the specified thickness.
// Arguments:
//   thickness = Thickness value in millimeters
// Returns:
//   Material vector for MDF with Tan texture
function MDF(thickness) = material_new("MDF", thickness, texture_new("Tan"));

// Function: DEFAULT_MATERIAL()
// Synopsis: Creates the default fallback material.
// Description:
//   Creates a default material with very low layer priority (-1000) to ensure
//   it can be overridden by any paint or material texture. Used as the default
//   context material when no material is explicitly set.
// Arguments:
//   thickness = Thickness value in millimeters
// Returns:
//   Material vector for default material with Gray texture at layer -1000
function DEFAULT_MATERIAL(thickness) = material_new("Default", thickness, texture_new("Gray", layer=-1000));
