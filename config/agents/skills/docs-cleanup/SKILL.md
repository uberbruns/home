---
name: docs-cleanup
description: Clean up documentation, prose, code comments, README files, guides, specs, and examples for clarity, concision, structure, terminology, and codebase accuracy.
---

Write with purpose. Every sentence must deliver value to the reader.

Apply each item systematically. Preserve the document's technical meaning unless local evidence shows that the existing content is wrong.

### Phase 1: Verify Content

- [ ] Read the target documentation and enough surrounding code or context to verify the claims.
- [ ] Correct statements that contradict the current implementation.
- [ ] Remove stale historical context unless it explains a current constraint.
- [ ] Keep code examples aligned with real patterns from the codebase.
- [ ] Comment only on behavior that is not obvious from the code or example.

### Phase 2: Improve Tone

- [ ] State points clearly without unnecessary preamble.
- [ ] Present decisions and information with authority.
- [ ] Remove filler words, redundant explanations, and obvious statements.
- [ ] Assume reader competence and intelligence.
- [ ] Focus on what to do, not what might be possible.
- [ ] Make content accessible to readers with different experience levels.
- [ ] Use correct terminology that beginners can learn and experts expect.
- [ ] Be brief without degrading readability.
- [ ] Retain connecting words when complex reasoning requires them.

### Phase 3: Tighten Length

- [ ] Keep only essential information.
- [ ] Respect the reader's time.
- [ ] Ensure every sentence and bullet point has an explicit subject, verb, and object.
- [ ] Avoid subjectless fragments.
- [ ] Expand telegraphic phrases into full sentences.
- [ ] Break compound bullet points into separate sentences when they describe distinct actions.
- [ ] Add articles such as "a" and "the" to noun phrases in definitions and descriptions.
- [ ] Use words like "because" or "with this in mind" when they help readers follow complex reasoning.

### Phase 4: Remove Weak Language

- [ ] Eliminate hedging language such as "perhaps", "maybe", and "it might be".
- [ ] Remove apologetic tone such as "sorry for the confusion".
- [ ] Avoid condescending explanations of basic concepts.
- [ ] Cut verbose introductions that delay the main point.
- [ ] Remove repetitive statements that add no new information.
- [ ] Eliminate promotional language and unnecessary praise for authors, teams, readers, implementations, decisions, or actions.
- [ ] Remove subjective arguments that cannot be substantiated with evidence.
- [ ] Avoid gendered language and assumptions about gender.
- [ ] Remove gendered personal pronouns, especially in code comments.
- [ ] Avoid emojis in documentation.

### Phase 5: Structure the Document

- [ ] Use bullet points for lists instead of paragraph form.
- [ ] Keep sentences under 25 words when possible.
- [ ] Group related points under clear headings.
- [ ] Keep heading hierarchy shallow and consistent.
- [ ] Prefer concrete labels over clever or decorative section names.

### Phase 6: Apply RFC 2119 Keywords

Use RFC 2119 keywords only when the text defines explicit requirements.

- [ ] Use **MUST**, **REQUIRED**, or **SHALL** for absolute requirements.
- [ ] Use **MUST NOT** or **SHALL NOT** for absolute prohibitions.
- [ ] Use **SHOULD** or **RECOMMENDED** for strong recommendations with rare exceptions.
- [ ] Use **SHOULD NOT** for strong recommendations against an action, with rare exceptions.
- [ ] Use **MAY** or **OPTIONAL** for truly optional choices.

### Phase 7: Review Code Examples

- [ ] Show real patterns from the codebase.
- [ ] Keep examples minimal enough to highlight the documented behavior.
- [ ] Name variables and functions consistently with the surrounding project.
- [ ] Remove comments that explain obvious syntax or direct assignments.
