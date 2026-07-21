# The Composition Root

Where abstract protocols get bound to concrete implementations — the only file
that imports every layer.

## Overview

Every layer above deals only in protocols (`UserRepository`, a use case, ``Router``,
``UserListFlow``). Something has to instantiate the concrete types and wire them
together — that something is `CompositionRoot`, the *only* type allowed to import
`Domain`, `Data`, and `Presentation` at once.

It owns the app-wide services and the navigation map:

```swift
// Sources/App/CompositionRoot.swift
struct CompositionRoot {
    let modelContainer: ModelContainer
    let session = SessionStore()
    let registry = DestinationRegistry()
    let tabs = [ /* each with its own AppRouter */ ]
    private let repository: UserRepository
}
```

Route registration is where presentation mode is *not* decided and where each
destination is handed the router of the wireframe that presents it — so a screen
inside a modal acts on that modal's context:

```swift
registry.register(UserDetailRoute.self) { route, router in
    UserDetailView(store: UserDetailStore(
        user: route.user,
        toggleFavorite: DefaultToggleFavoriteUseCase(repository: repository),
        setRelated: DefaultSetRelatedUserUseCase(repository: repository),
        flow: RelatedUserFlow(router: router)
    ))
}
```

Swapping `DefaultUserRepository` for a real networking implementation tomorrow is a
change to this file alone. Every store, view, and test stays untouched.

## Concurrency choices

- **`async/await`** across every boundary (use case → repository → data source)
  instead of completion handlers — errors propagate with `throws`, cancellation is
  automatic.
- **`actor` for shared mutable state** (the remote data source) instead of locks.
- **Main-actor by default** (Swift 6.2 `defaultIsolation`): stores, the router,
  flows, and the repository/use-case contracts are all main-actor, because
  SwiftData `@Model` objects aren't `Sendable` and every consumer already lives on
  the main actor. Only the remote data source crosses an actor boundary, exchanging
  `Sendable` DTOs, never models. Local mutations (toggling a favorite, setting a
  relation) are synchronous end to end — no optimistic-update/rollback dance.

## Topics

- <doc:Testing>
