---
name: moia-code-documentation
description: Add code documentation to changed files on the current branch. Use when documenting new or modified APIs, protocols, or public types.
disable-model-invocation: true
---

# Add Code Documentation

Add documentation to code changed on this branch.

## Step 1: Identify Changes

Use `git diff` to find all changes between this branch and its parent branch.

## Step 2: Document These Elements

- Protocols and their public methods
- Public classes, structs, and enums (especially API boundaries)
- Non-obvious public properties, especially publishers
- Complex business logic and algorithms
- Extensions that add significant functionality

## Step 3: Documentation Style

Generate Swift-style `///` comments that:

- Provide a brief, clear description of purpose
- Use concise language explaining "what" not "how"
- Document parameters with `- Parameter:` / `- Parameters:` format
- Include references to external docs for complex components
- Keep descriptions focused and to the point

## Step 4: Skip These

- Private implementation details
- Simple UI setup methods
- Simple delegate implementations
- Self-explanatory properties
- Basic lifecycle methods
- Extensions that just conform to standard protocols
- Obvious methods (like simple setup methods)
