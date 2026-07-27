# ADR-0003: Make the Domain entity a SwiftData `@Model`, and `@Query` the Model of MVI

- **Status**: accepted
- **Date**: 2025-09-13
- **Supersedes**: [ADR-0004](0004-observation-stream-for-cross-feature-updates.md)

## Context

Toggling a favorite on the detail screen did not update the list. Each store
held its own snapshot of the users, so any change had to be pushed to every
other screen showing the same data. [ADR-0004](0004-observation-stream-for-cross-feature-updates.md)
solved this with a repository-owned `AsyncStream`, which worked but was a
hand-rolled reimplementation of change propagation: continuations, broadcast,
per-store subscription and lifecycle.

The layers also paid a permanent tax for storage: a `UserDTO` for persistence,
an in-memory cache actor, and the mapping between them.

## Decision

The Domain entity `User` is a SwiftData `@Model` class. One type is
simultaneously the persistence schema, the persisted row, the observable object
views react to, and the navigation payload.

Views read collections with `@Query`, which observes the store directly — that
is the **Model** half of the MVI loop. Feature `State` structs keep only
transient UI state (loading, error). The repository contract shrinks to
mutations (plus a single point read added later for deep links, see
[ADR-0009](0009-deep-links-over-value-routes.md)).

## Alternatives considered

- **Keep the `AsyncStream`** ([ADR-0004](0004-observation-stream-for-cross-feature-updates.md))
  — architecturally purer (Domain stays framework-free) but reimplements what
  the framework already does, and every new screen must subscribe correctly.
- **Keep `User` a struct and map to a separate `@Model` entity in Data** —
  preserves Clean purity; costs the DTO↔entity mapping, and `@Query` can then
  only return the persistence type, so the mapping resurfaces in the views.
- **Callbacks between stores** (the original `userWasAdded`) — does not scale:
  every new cross-feature effect adds another wire.

## Consequences

- Deleted outright: the observation stream, the local cache actor, the storage
  DTO mapping, and two use cases (`ObserveUsers`, `FetchUserDetail`). Net
  −214 lines at the time of the change.
- A mutation made anywhere re-renders every screen showing that object, with no
  callbacks — this is what makes modals that "return a value" (the related-user
  picker) need no result plumbing at all.
- **Domain imports SwiftData.** This is the deliberate cost: the innermost layer
  is no longer framework-free.
- Favorites and locally created users now persist across launches, so the mock
  remote must return **stable seed UUIDs** or every launch duplicates rows.
- Schema changes that are not lightweight migrations (to-one → to-many, see
  [ADR-0010](0010-many-to-many-related-users.md)) require reinstalling the app.
- **Escape hatch**: if storage ever moves off SwiftData, `User` becomes a plain
  struct again and a mapping layer returns to `Data`.
