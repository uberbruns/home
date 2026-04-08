---
name: swift-documentation
description: Apply Swift documentation standards and patterns
---

Document Swift code with appropriate detail and clarity.

**IMPORTANT:** Each phase and every checklist item within it MUST be applied diligently and systematically. Do not skip phases, gloss over individual items, or mark items as done without verifying them against the code. Work through the phases in order and treat each checklist item as a discrete step that requires explicit attention.

### Phase 1: Verify Existing Documentation

- [ ] Read the existing documentation comments in the target file.
- [ ] Cross-check each documented claim (parameter descriptions, return values, thrown errors, behavioral statements) against the actual implementation.
- [ ] Flag any documentation that contradicts the code, references renamed or removed symbols, or describes outdated behavior.
- [ ] Remove or correct stale documentation before writing new content.

### Phase 2: Write and Update Documentation

- [ ] Full documentation for public APIs and entry points only.
- [ ] Single-line docs for implementation details (2-3 lines for complex methods).
    - [ ] Focus on what the API does for the consumer.
- [ ] Code symbol documentation should not explain implementation details that are irrelevant to the caller or may be subject to change.
- [ ] Ensure terminology is aligned with the implementation. Default to consistent terminology and only use synonyms in longer explanations to enhance understanding.
- [ ] Do not make claims that cannot be verified with the local code.

### Phase 3: Add Developer Note (Optional)

Only add a Developer Note to complex files where the code alone does not convey the full picture.

- [ ] Focus on meaningful, non-obvious information.
- [ ] Use normal `//` comments (not `///` documentation comments).
- [ ] Lead with "Developer Note:\n".
- [ ] Place between imports and the first (main) declaration (before its MARK statements).
- [ ] Lead the Developer Note with an elevator pitch explaining the type's role in the broader project.
- [ ] Summarize the applied business rules.
- [ ] Write fully formed, not abbreviated, sentences.
- [ ] Add a glossary for domain-specific or non-obvious naming choices.
- [ ] Document meaningful or surprising workarounds.

### Phase 4: Format Code References

- [ ] Surround code symbols with backticks when referenced in documentation.
    - Type names: `User`, `AuthenticationService`
    - Property names: `userName`, `isAuthenticated`
    - Method names: `authenticate()`, `fetchUser(withID:)`
    - Parameter names: `username`, `completion`
    - Keywords: `nil`, `true`, `false`
    - Code expressions: `user.name`, `results.count > 0`

### Phase 5: Apply Writing Standards

**Tone**

- [ ] State points clearly without unnecessary preamble.
- [ ] Present decisions and information with authority.
- [ ] Remove filler words, redundant explanations, and obvious statements.
- [ ] Assume reader competence and intelligence.
- [ ] Focus on what is, not what might be possible.
- [ ] Make content accessible to readers with different experience levels.
- [ ] Use correct terminology that beginners can learn and experts expect.
- [ ] Be brief without degrading readability; retain connecting words and transitions when complex reasoning requires them.
- [ ] Focus on the current state and remove information that requires historical context.

**Length**

- [ ] Be brief by sticking to essential information. Respect the reader's time.
- [ ] Ensure every sentence and bullet point has an explicit subject, verb, and object.
- [ ] Avoid subjectless fragments.
- [ ] Expand telegraphic phrases into full sentences.
- [ ] Break compound bullet points into separate sentences when they describe distinct actions.
- [ ] Add articles ("a", "the") to noun phrases in definitions and descriptions.
- [ ] Do not shy away from words like "because" or "with this in mind" that help readers follow complex reasoning.

### Phase 6: Update MARK Comments

Apply MARK comment structure by invoking the following skills as separate subagents, one after another:

- [ ] Invoke `/swift-file-level-marks` to update file-level MARK comments.
- [ ] Invoke `/swift-type-level-marks` to update type-level MARK comments.
