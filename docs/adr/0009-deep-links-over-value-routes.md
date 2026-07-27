# ADR-0009: Handle deep links by building the same route values in-app flows build

- **Status**: accepted
- **Date**: 2025-09-15

## Context

Deep links were the empirical test of
[ADR-0006](0006-routes-as-values-with-a-destination-registry.md): if routes are
values rather than view builders, an incoming URL should become ordinary
navigation with no dedicated machinery. A URL also arrives with an *identifier*,
not an object, while routes carry the resolved `@Model` — and it can arrive
while the user is logged out.

## Decision

`DeepLink` parses a URL into a value (`mviexample://users`, `user/<uuid>`,
`add-user`). `DeepLinkCoordinator` resolves any id and sends **the very same
route value an in-app flow would build** to the target tab's router; the
registry and wireframe present it unchanged. A link arriving while
unauthenticated is held pending and applied on login.

Resolving an id required the single point read on the repository
(`user(id:)` + `FetchUserUseCase`) — the documented exception to "reading is
`@Query`'s job", because a deep link resolves an entity outside any view.

## Alternatives considered

- **A parallel deep-link presentation path** — the usual outcome when routes are
  closures: link handling reimplements screen construction. Unnecessary here.
- **Drop links received while logged out** — simpler, and wrong for the session
  gate this app has.
- **Routes carrying ids instead of objects** — would let the whole
  `NavigationPath` be `Codable` (state restoration), but reintroduces
  loading/not-found states in every detail screen. Deferred: deep links were the
  requirement, restoration was not.

## Consequences

- Zero deep-link-specific presentation code; the feature is a parser plus a
  coordinator.
- Deep links reach the correct tab and survive the login gate.
- The repository gains one read method, narrowing the "mutations only" rule.
- Registering a URL scheme needs `CFBundleURLTypes` (an array), which forced the
  move from `GENERATE_INFOPLIST_FILE` to an explicit generated Info.plist
  ([ADR-0002](0002-xcodegen-for-the-app-target.md)).
- State restoration remains open, and would require the id-based routes rejected
  above.
