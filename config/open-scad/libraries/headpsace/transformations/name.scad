// Name modules for hierarchical naming

include <../models/context/context.scad>
include <context.scad>

// Module: name()
// Synopsis: Sets the context to a single name component and executes children.
// Description:
//   Sets the context to contain only the given name component and executes child modules.
//   This replaces the entire naming hierarchy with a single name.
// Arguments:
//   name_component = Name component to set as the context
module name(name_component) {
  update(context_name_components_set(context_current(), [name_component])) children();
}

// Module: push_name()
// Synopsis: Pushes a name to the context hierarchy and executes children.
// Description:
//   Adds the given name to the context and executes child modules with the updated context.
//   This enables hierarchical naming throughout the module tree.
// Arguments:
//   name_component = Name component to push_name to the context
module push_name(name_component) {
  update(context_name_components_push(context_current(), name_component)) children();
}

// Module: pop_name()
// Synopsis: Pops the last name component from the context hierarchy and executes children.
// Description:
//   Removes the last name component from context and executes child modules with the updated context.
//   This enables removing a level from the hierarchical naming.
module pop_name() {
  update(context_name_components_pop(context_current())) children();
}
