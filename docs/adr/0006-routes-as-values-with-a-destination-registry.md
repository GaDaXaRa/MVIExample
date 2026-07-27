# ADR-0006: Describe screens as route values resolved by a destination registry

- **Status**: accepted
- **Date**: 2025-09-14

## Context

Navigation started as an `AppRouter` with a central `Route` enum: one case per
pushable screen, matched in a `switch` inside the root view's
`navigationDestination`. Two problems surfaced.

First, a central enum is a coupling point: every new screen edits a type all
features share, which does not scale across modules or teams.

Second — the requirement that forced the redesign — the same screen had to be
presentable as a push *or* as a modal without knowing which. SwiftUI's
`navigationDestination(for:)` binds a type to push specifically, so a typed
registration is push-only by construction.

A reference implementation was available in an existing in-house library
(Santalucia's `Wireframe`), where a `Destination` carries a **closure that
builds the view**, so any feature can present anything with no shared enum.

## Decision

Screens are described by **route values**: each feature declares its own small
`Hashable` struct conforming to `Route`, saying *what* to show, never *how*.

A `DestinationRegistry`, filled once by the composition root, maps route types
to view builders — with the presentation mode deliberately *not* part of the
registration. `WireframeView` resolves a route through the registry at
presentation time, so the same route can be pushed, sheeted or covered
interchangeably (see [ADR-0007](0007-wireframe-owns-presentation.md)).

## Alternatives considered

- **Central `Route` enum** — simplest for one module, but every feature edits a
  shared type, and it stayed push-only.
- **Per-feature `navigationDestination` extensions** (typed, no `AnyView`) —
  decentralized and fully typed; implemented and then rejected because it binds
  each route to push only, defeating the presentation-agnostic requirement.
- **`Destination` closures, as in the reference library** — decentralized and
  mode-agnostic, but the value travelling the router *is* a view builder:
  identity is a UUID, so `popTo` cannot work by equality (the original library's
  `popTo` was in fact broken), paths cannot be `Codable`, tests can only assert
  "something was presented", and whoever navigates needs the destination's
  dependencies to build it.

## Consequences

- No shared screen enum: features stay decoupled, each owning its route type.
- Routes are comparable values, so `popTo` works by equality, and a route can be
  **constructed from a URL** — which is what made deep links a ~70-line addition
  with no navigation-specific presentation code
  ([ADR-0009](0009-deep-links-over-value-routes.md)).
- Tests assert *where* navigation went, not merely that it happened.
- Cost: one deliberate `AnyView`, inside the registry — a map of heterogeneous
  view builders cannot be typed. At a screen boundary the erasure is free.
- Cost: a route pushed without a registration fails at runtime
  (`assertionFailure`), not at compile time.
- `AppRouter` must keep a mirror array of pushed routes beside the opaque
  `NavigationPath`, reconciled when the user pops interactively.
