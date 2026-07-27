# ADR-0005: Adopt Swift 6.2 default MainActor isolation

- **Status**: accepted
- **Date**: 2025-09-13

## Context

After [ADR-0003](0003-swiftdata-model-as-the-domain-entity.md), `@Model` objects
are main-actor-bound and every consumer — stores, the router, use cases, the
`ModelContext` — already lived on the main actor. The codebase carried ~12
`@MainActor` annotations restating that, plus `Sendable` conformances on
contracts that never crossed an actor boundary.

Swift's historical default ("nonisolated unless stated") is the wrong default
for app code, where nearly everything is main-actor: it forces annotations to
tell the compiler the obvious, and produces the familiar "call to main
actor-isolated method in a nonisolated context" wall.

## Decision

Every target sets `.defaultIsolation(MainActor.self)` (SE-0466, "Approachable
Concurrency"); the App target sets `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`.
Concurrency becomes **opt-in and explicit**: `actor` for the one real boundary
(the mock remote data source) and `nonisolated` for inert values that must
cross it (`UserDTO`, and later `Route` conformers).

## Alternatives considered

- **Keep annotating `@MainActor` everywhere** — works, but repeats the default
  ~12 times and keeps the error class alive.
- **Push work off the main actor by default** — the pattern for a library or a
  processing pipeline, not for a UI app whose model layer is main-actor-bound.

## Consequences

- All redundant `@MainActor` annotations deleted; concurrency intent is now
  visible precisely where it exists.
- Same Swift 6 strict-concurrency guarantees: only the starting point changed.
- Requires Swift 6.2 (`swift-tools-version: 6.2`).
- New surprise to know about: a type's *synthesized* conformances also become
  main-actor-isolated, which is why `Route` conformers must be declared
  `nonisolated` — otherwise their `Hashable` fails to compile when used as
  navigation path values.
- Anything genuinely heavy added later must be marked explicitly, or it runs on
  the main thread by default.
