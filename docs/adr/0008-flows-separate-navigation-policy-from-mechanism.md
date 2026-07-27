# ADR-0008: Split navigation into per-feature flows (policy) and the router (mechanism)

- **Status**: accepted
- **Date**: 2025-09-14

## Context

Stores called the router directly (`router.send(.push(UserDetailRoute(user:)))`),
which meant `UserListStore` knew `UserDetailRoute` — a feature-to-feature
coupling — and, worse, hard-coded *what selecting a user means*.

The requirement that exposed it: the same user list should push a detail in one
context, show the user's data in an alert in another, and assign a relation and
dismiss in a third. With destinations chosen inside the store, that needs three
stores or a mode flag threaded through the store.

## Decision

Each feature owns a **flow protocol** in domain language — `UserListFlow` with
`didSelectUser(_:)`, `AddUserFlow` with `didFinish()`. The store reports *what
happened*; it never names a destination. Concrete flows live in
`Presentation/Flows/`, are injected by the composition root, and translate
events into router intents.

```
Store ──semantic event──▶ Flow (policy) ──▶ Router (mechanism) ──▶ Wireframe
```

Rarely-wired events get default no-op implementations, so a context only wires
what its chrome exposes.

## Alternatives considered

- **Stores call the router** — what existed; couples features and fixes
  behavior at the store.
- **Return a navigation event in `State` for the view to interpret** — puts
  navigation back into screen state, which
  [ADR-0006](0006-routes-as-values-with-a-destination-registry.md) and
  ADR-0007 deliberately removed.
- **A closure per navigation event** (`onSelectUser: (User) -> Void`) — works
  for one event; becomes an unnamed parameter list as features grow, and the
  set of events stops being a documented contract.

## Consequences

- The same `UserListView`/`UserListStore` now serves four contexts —
  `BrowseUsersFlow`, `PickUserFlow`, `PickRelatedUserFlow` (later
  `RelatedListFlow`) — by injecting a different flow and touching nothing else.
- Features no longer know each other: knitting screens together is the flow's
  job, and flows are the only types allowed to know several features.
- Tests split cleanly by level: store tests assert semantic events on a flow
  spy; flow tests assert the resulting router intents against a real router.
- Cost: one protocol plus one implementation per feature. Ceremony when a screen
  has exactly one context — it pays off at the second one.
- Data mutations (toggle favorite, remove, set relation) deliberately do **not**
  go through flows: they are use-case calls, not navigation.
