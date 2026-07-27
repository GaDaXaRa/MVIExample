# ADR-0001: Combine Clean Architecture with MVI, enforced by SPM targets

- **Status**: accepted
- **Date**: 2025-09-12

## Context

The repository is a reference template: its product is the architectural
criterion, not the sample user-directory app. Two concerns must be answered —
how the code is layered, and how a single screen manages its state — and they
are frequently conflated into one pattern that does both badly.

Layering conventions that live only in prose ("Presentation must not import
Data") get violated silently and are only caught, if ever, in code review.

## Decision

Two patterns at different scopes, composed:

- **Clean Architecture** decides the layering: `Domain` (entities, repository
  contracts, use cases), `Data` (DTOs, data sources, repository
  implementations), `Presentation` (features).
- **MVI** decides per-screen state: a `State` struct, an `Intent` enum, and a
  `Store` that turns intents into state — one synchronous `send(_:)` as the
  only entry point.

Each layer is a separate SPM target, so the Dependency Rule is a build
setting: `Presentation` cannot `import Data` because it is not a declared
dependency. Attempting it is a compile error, not a review comment.

## Alternatives considered

- **One target with folder conventions** — zero ceremony, but the dependency
  rule becomes unenforceable; the first deadline breaks it.
- **MVVM instead of MVI** — familiar, but a view model with N mutable
  properties has no single funnel for changes, which is what makes the state
  transitions here testable one intent at a time.
- **A full framework (TCA)** — solves this and much more, at the cost of a
  large dependency and its own vocabulary. The point of the template is to
  show the pattern in plain Swift/SwiftUI.

## Consequences

- Layer violations are impossible rather than discouraged.
- Every screen's behavior is testable by sending intents and asserting state,
  with no UI involved.
- More files and more boilerplate than a single-target app: each feature is a
  `<Feature>Feature.swift` (State/Intent/Store) plus a `<Feature>View.swift`.
- The `App` target cannot be an SPM `executableTarget` (it would not produce an
  installable `.app`), so it is generated with XcodeGen — see
  [ADR-0002](0002-xcodegen-for-the-app-target.md).
