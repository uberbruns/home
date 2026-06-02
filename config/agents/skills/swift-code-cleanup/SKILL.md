---
name: swift-code-cleanup
description: Comprehensive Swift code cleanup orchestrator
---

Apply comprehensive Swift code cleanup by executing specialized cleanup skills in optimal order.

This skill spawns subagents to systematically apply each cleanup category. The agents execute sequentially to ensure changes build upon each other coherently.

**IMPORTANT:** Each phase and every checklist item within it MUST be applied diligently and systematically. Do not skip phases, gloss over individual items, or mark items as done without verifying them against the code. Work through the phases in order and treat each checklist item as a discrete step that requires explicit attention.

## Execution Order

The system applies cleanup skills in the following order for optimal results:

1. **Remove Obsolete Code** - Eliminate dead code before refactoring
2. **Refactoring** - Restructure code architecture and patterns
3. **Method Body** - Organize internal method structure
4. **Naming** - Apply consistent naming conventions
5. **Documentation** - Add and update code documentation
6. **File Structure** - Organize file and type layout
7. **File-Level Marks** - Add file-level MARK comments (with dash)
8. **Type-Level Marks** - Add type-level MARK comments (without dash)
9. **Inline Comments** - Add subheading comments in method bodies
10. **Vertical Whitespace** - Apply vertical spacing rules

## Instructions

### Phase 1: Manual Cleanup Skills

**Per-file parallelization:** The orchestrator MUST spawn one general-purpose subagent per target file. All file-level subagents run in parallel.

**Per-skill isolation:** Each file-level subagent MUST process the execution list sequentially, spawning a fresh general-purpose subagent for each skill. A clean subagent per skill ensures that each step starts with a clear context and avoids accumulated drift from prior edits.

The workflow proceeds as follows:

1. The orchestrator identifies all target files.
2. The orchestrator spawns one subagent per file (in parallel).
3. Each file subagent iterates through the skill list in order and, for every skill, spawns a new subagent that:
   - Reads the current state of the file
   - Applies the skill checklist systematically and diligently
   - Questions everything — no item is skipped without justification
   - Makes necessary edits to the file
   - Reports completed changes back to the file subagent
4. The file subagent waits for each skill subagent to finish before spawning the next one, so that later skills build on earlier changes.

**Skill execution order (each applied by its own subagent):**

1. `/swift-remove-obsolete` - Remove obsolete and trivial code
2. `/swift-refactoring` - Apply refactoring patterns
3. `/swift-method-body` - Structure method bodies
4. `/swift-naming` - Apply naming conventions
5. `/swift-documentation` - Add documentation
6. `/swift-file-structure` - Organize file structure
7. `/swift-file-level-marks` - Add file-level MARK comments (with dash)
8. `/swift-type-level-marks` - Add type-level MARK comments (without dash)
9. `/swift-inline-comments` - Add inline subheading comments
10. `/swift-vertical-whitespace` - Apply vertical whitespace rules

### Phase 2: Automated Formatting and Linting Tools

Search for and execute automated Swift formatting and linting tools configured in the project:

1. **Search for configuration files:**
   - Use Glob to find `CLAUDE.md`, `AGENTS.md`, `Makefile`, `mise.toml`, `.mise.toml` in the project
   - Read each found file and search for Swift formatting/linting tool references:
     - `swift-format`, `swiftformat`, `swiftlint`, or similar tools
     - Format/lint commands or make targets
     - mise tasks related to formatting or linting

2. **Execute automated tools if found:**
   - For `Makefile`: Check for targets like `format`, `lint`, `fmt`, `swift-format`
     - Run with `make <target>`
   - For `mise`: Check available tasks with `mise tasks`
     - Look for format/lint tasks and run with `mise run <task>`
   - For `CLAUDE.md`/`AGENTS.md`: Look for documented formatting/linting commands and execute them
   - Capture and report any errors or warnings from automated tools
   - Verify the file compiles without errors

3. **Report summary:**
   - List all changes made in Phase 1
   - Report results from automated tools in Phase 2
   - Note any remaining issues or warnings
