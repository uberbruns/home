---
name: swift-documentation
description: Apply Swift documentation standards and patterns
---

Document Swift code with appropriate detail and clarity.

### Documentation

- [ ] Full documentation for public APIs and entry points only
- [ ] Single-line docs for implementation details (2-3 lines for complex methods)
- [ ] Code symbol documentation should not explain implementation details that are irrelevant to the caller or may be subject to change.
- [ ] Developer Note (Optional, only add for complex files)
    - [ ] Use normal `//` comments (not `///` documentation comments)
    - [ ] Place between imports and the first (main) declaration
    - [ ] Lead the Developer Note with an elevator pitch explaining the type's role in the broader project
    - [ ] Summarize the applied business rules
    - [ ] Add a glossary for domain-specific or non-obvious naming choices
    - [ ] Document meaningful or surprising workarounds

### Code References

- [ ] Surround code symbols with backticks when referenced in documentation
    - Type names: `User`, `AuthenticationService`
    - Property names: `userName`, `isAuthenticated`
    - Method names: `authenticate()`, `fetchUser(withID:)`
    - Parameter names: `username`, `completion`
    - Keywords: `nil`, `true`, `false`
    - Code expressions: `user.name`, `results.count > 0`

### Writing Tone

- [ ] State points clearly without unnecessary preamble
- [ ] Present decisions and information with authority
- [ ] Remove filler words, redundant explanations, and obvious statements
- [ ] Assume reader competence and intelligence
- [ ] Focus on what is, not what might be possible
- [ ] Make content accessible to readers with different experience levels
- [ ] Use correct terminology that beginners can learn and experts expect
- [ ] Be brief without degrading readability; retain connecting words and transitions when complex reasoning requires them
- [ ] Focus on current state and remove information that requires historical context

### Length

- [ ] Be brief by sticking to essential information. Respect the readers time
- [ ] Ensure every sentence and bullet point has an explicit subject, verb, and object
- [ ] Avoid subjectless fragments
- [ ] Expand telegraphic phrases into full sentences
- [ ] Break compound bullet points into separate sentences when they describe distinct actions
- [ ] Add articles ("a", "the") to noun phrases in definitions and descriptions
- [ ] Do not shy away from words like "because" or "with this in mind" that help readers follow complex reasoning