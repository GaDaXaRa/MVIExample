# ADR-0012: Keep architecture documentation in DocC catalogs, not one markdown file

- **Status**: accepted
- **Date**: 2025-09-16

## Context

`ARCHITECTURE.md` was a 500-line walkthrough. It drifted: by the time it was
migrated it still showed a `UserRepository` with `fetchUsers`, a composition
root that no longer existed, and stores that had been rewritten twice. Nothing
detected the drift, because prose mentioning `Store` has no link to `Store`.

## Decision

The canonical documentation lives in **DocC catalogs** — one in the
`Presentation` target (this app's architecture, six articles) and one in the
`Wireframe` package (the kit plus an adoption guide). Symbol references use
DocC links, so they resolve to the real API and **warn at documentation-build
time when a symbol disappears**.

`ARCHITECTURE.md` remains at the root as a short pointer with an article index,
because GitHub cannot render DocC. `AGENT_GUIDE.md` also stays at the root: its
audience is tooling that reads the repository, not Xcode.

## Alternatives considered

- **Keep the monolithic markdown** — renders on GitHub, but rots silently and
  cannot link to symbols.
- **Only doc comments in code** — great for API reference, poor for explaining
  a pattern that spans layers.
- **A separate documentation site** — more reach, more maintenance, and further
  from the code than the Xcode documentation window.

## Consequences

- Documentation is compiled: a renamed type produces a warning instead of a
  stale sentence, and `swift package generate-documentation` gates it.
- It is readable where the work happens (⇧⌘0), and publishable to Pages via
  `--transform-for-static-hosting`.
- Each package needs `swift-docc-plugin` as a dependency.
- Doc edits must be followed by regenerating the catalogs, or broken links go
  unnoticed — the same failure mode as before, only now detectable.
- GitHub visitors see the pointer, not the content: a deliberate trade for
  documentation that stays true.
