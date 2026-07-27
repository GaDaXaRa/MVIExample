# ADR-0011: Extract the domain-agnostic core into its own SPM package

- **Status**: accepted
- **Date**: 2025-09-16

## Context

`Presentation/Core` had grown into two very different kinds of code: a generic
app-shell kit (the `Store` contract, the router, the wireframe, the registry,
the session gate) that knows nothing about users, and three files that do know
`User` (`DeepLink`, `DeepLinkCoordinator`, `UserRow`).

Nothing prevented the generic half from acquiring an `import Domain`. Targets
enforce direction between app layers, but a target can still be pointed at
another target in the same package.

## Decision

The generic core moves to `Wireframe/`, a **separate local SPM package**
depending only on SwiftUI and Observation, with its own test target and DocC
catalog. `Presentation` depends on `Domain` + `Wireframe`, never on `Data`. The
three app-coupled files move out of `Core` into `Presentation/DeepLink` and
`Presentation/Components`; `Core` disappears.

## Alternatives considered

- **Keep it a folder in `Presentation`** — zero ceremony, but "the kit must not
  know about the app" stays a convention.
- **A separate *target* in the same package** — most of the benefit, yet a
  target can still be made to depend on an app target; the boundary remains
  editable.
- **Publish it as a remote package immediately** — premature: it has exactly one
  consumer, and versioning it now would slow iteration.

## Consequences

- The kit *cannot* reach into `Domain` or a feature: with a separate package the
  dependency is one-way by construction.
- It can be reused as-is by another app, and could move to its own repository
  with semantic versioning without further refactoring.
- Two packages to build and test (`swift test` at the root, and inside
  `Wireframe/`), and two DocC catalogs.
- Cross-module symbol links do not resolve in DocC, so the Presentation catalog
  now refers to kit types as plain code spans rather than symbol links.
- For a single app the reuse payoff is still theoretical; the boundary
  enforcement and the documented kit are the immediate gains.
