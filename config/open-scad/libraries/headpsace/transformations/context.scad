// Context stack management modules

include <../models/context/context.scad>

// Module: update()
// Synopsis: Updates the current context on the stack.
// Description:
//   Replaces the current context (last element in stack) with the given context.
// Arguments:
//   context = Context vector to replace the current context with
module update(context) {
  $context_stack = context_update(context);
  children();
}

// Module: save()
// Synopsis: Saves the current context by pushing a copy onto the stack.
// Description:
//   Copies the current context and pushes it onto the context stack.
//   This allows for later restoration with restore().
module save() {
  $context_stack = context_push(context_current());
  children();
}

// Module: restore()
// Synopsis: Restores the previous context by popping from the stack.
// Description:
//   Pops the last context from the context stack, restoring the previous context state.
//   The depth value from the current context is preserved and applied to the restored context.
//   This should be paired with a previous save() call.
module restore() {
  $context_stack = context_pop_preserve_depth();
  children();
}

// Module: increase_depth()
// Synopsis: Increments the depth value in the current context.
// Description:
//   Increases the depth property of the current context by 1.
//   The modified context is applied to all children.
module increase_depth(i = 1) {
  update(context_depth_increment(context_current(), i=i)) children();
}
