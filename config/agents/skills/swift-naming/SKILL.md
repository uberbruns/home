---
name: swift-naming
description: Apply Swift naming conventions and patterns
---

Apply consistent, clear naming conventions following Swift API Design Guidelines.

Question every existing naming.

### Naming

- [ ] **Consistency** - Use the same name for identical concepts throughout the code; avoid synonyms (e.g., choose `path`, `directory`, or `folder` and use consistently rather than mixing them)
- [ ] **Variables** - Specific, unabbreviated names that communicate purpose without extra context
- [ ] **Functions** - Name matches purposes and implementation in body
- [ ] **Specificity** - Prefer precise terms over generic ones; derive from symbol/function docs
- [ ] **Length** - Names should be long enough to be unambiguous and short enough to be scannable; the right name feels obvious in retrospect. Err on the side of too long rather than too short.
- [ ] **Weight** - Reserve generic verbs (`get`, `set`) for lightweight accessors; use more descriptive verbs (`discover`, `compute`, `load`) for non-trivial operations
- [ ] **Symmetry** - Similarly purposed functions may share leading or trailing terms
- [ ] **Type pattern** - `<adjective>?` + `<noun>` (e.g. `User`, `CachedTokenProvider`)
- [ ] **Function pattern** - `<verb>` + `<adjective>?` + `<noun>` + `<context>?` (e.g. `fetchActiveUsers`, `validateInputFormat`, `buildNavigationStack`)
- [ ] **State pattern** - `<gerund/noun>` + `<verb (past-tense)>` + `<context>?` (e.g. `loadingFinished`, `connectionEstablished`, `dataSynchronized`)
- [ ] **Boolean pattern** - `is` or `are` + `<adjective>?` + `<noun>` OR `<verb (3rd person present)>` + `<noun>` (e.g. `isLoading`, `isActive`, `areItemsAvailable`, `contains`, `hasItems`, `exists`)
- [ ] **Swift conventions** - Adhere to Swift API Design Guidelines and naming idioms
- [ ] **Reduce Ambiguity** - Avoid overloading terms from related technologies; reserve domain-specific terminology for its intended context (e.g., reserve `request` and `response` exclusively for HTTP operations when using an HTTP API)

### File and Type Names

- [ ] Type names and filenames should match when the file contains a single primary type
    - `User.swift` contains `struct User` or `class User`
    - `AuthenticationService.swift` contains `class AuthenticationService`
    - Files with multiple related types may use a descriptive name (e.g., `UserModels.swift`, `NetworkUtilities.swift`)
