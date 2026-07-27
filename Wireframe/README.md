# Wireframe

A domain-agnostic app shell for SwiftUI: the MVI store contract plus
intent-based, value-routed navigation.

Wireframe is the reusable half of an MVI + Clean Architecture app — the part
that knows nothing about any particular domain. It depends only on SwiftUI and
Observation.

```swift
// A screen is a value, not a view builder:
router.send(.push(UserDetailRoute(user: user)))
router.send(.sheet(UserDetailRoute(user: user)))   // the same screen, modally
```

## What's in the box

| | |
|---|---|
| `Store` / `PreviewStore` | The MVI contract: a `State` the view renders, an `Intent` vocabulary, one synchronous `send(_:)`. `PreviewStore` backs any `#Preview` with fixed state and no wiring. |
| `Route` / `AnyRoute` | Screens described as small `Hashable` **values** saying *what* to show, never *how*. |
| `Router` / `RouterIntent` / `AppRouter` | Navigation as a closed vocabulary of intents: `push`, `sheet`, `present`, `alert`, `pop`, `popToRoot`, `popTo`, `dismiss`. `Router` is a protocol, so tests can spy on it. |
| `WireframeView` / `DestinationRegistry` | The superior view owning every presentation container — stack, sheet, fullscreen cover, alert — resolving routes through a registry at presentation time. Modals become **child wireframes** with their own router; `dismiss` bubbles to the parent. |
| `SessionStore` | An observable authenticated/expired flag for the app root to switch on. |
| `AlertContent` | An alert described as a value, so flows can trigger one like any other presentation. |

Because the presentation mode is chosen by the caller and never by the
destination, **the same screen works pushed, sheeted or covered** with no
changes — and destination views carry no `NavigationStack` and no dismiss logic
of their own.

## Requirements

Swift 6.2 · iOS 17+ / macOS 14+. The package builds with
`.defaultIsolation(MainActor.self)` (SE-0466).

## Installation

```swift
// Package.swift
dependencies: [
    .package(path: "Wireframe")          // or .package(url:from:) once published
],
targets: [
    .target(
        name: "Presentation",
        dependencies: [.product(name: "Wireframe", package: "Wireframe")]
    )
]
```

## A 30-second tour

**1. Declare a route** — a value, `nonisolated` because routes are inert
identifiers that travel through `NavigationPath`:

```swift
public nonisolated struct UserDetailRoute: Route {
    public let user: User
}
```

**2. Register it with its view, once**, in your composition root. The
presentation mode is deliberately *not* part of the registration, and the
builder receives the router of the wireframe that will present it:

```swift
let registry = DestinationRegistry()
registry.register(UserDetailRoute.self) { route, router in
    UserDetailView(store: UserDetailStore(user: route.user, router: router))
}
```

**3. Wrap each root screen in a wireframe** (one `AppRouter` per independent
navigation context — typically one per tab):

```swift
WireframeView(router: tabRouter, registry: registry) {
    UserListView(store: makeUserListStore(router: tabRouter))
}
```

**4. Navigate by sending intents.** Modals need no extra work: anything sent
with `.sheet` or `.present` is wrapped in a child wireframe automatically, which
is what gives modals their own navigation and makes `.dismiss` bubble up.

The recommended shape on top is to keep stores out of the router entirely: have
them report semantic events (`didSelectUser(_:)`, `didFinish()`) to a small
per-feature flow protocol, and let flow types — owned by the composition —
translate those into router intents. The flow then picks the destination *and*
the mode, which is what lets the same screen navigate differently per context.

## Why routes are values

Because a `Route` is data rather than a view builder:

- `popTo` works by **equality** (`AppRouter` keeps a mirror of the pushed routes
  beside the opaque `NavigationPath`).
- A route can be **constructed from a URL**, so deep links reuse the exact same
  navigation path as in-app flows, with no link-specific presentation code.
- Tests assert *where* navigation went (`router.routes`,
  `router.presentedSheet`), not merely that something was presented.

The one type erasure lives inside `DestinationRegistry` — a map of
heterogeneous view builders cannot be typed — and a screen boundary is where
`AnyView` costs nothing.

## Documentation

Full API reference and the adoption guide ship as a DocC catalog:

```sh
swift package generate-documentation --target Wireframe
```

Or in Xcode: Product → Build Documentation (⌃⇧⌘D).

## Testing

`Router` is a protocol, so flows and stores can be tested against a spy or a
real `AppRouter`:

```swift
let parent = AppRouter()
parent.send(.sheet(EditorRoute()))
let child = AppRouter(parent: parent)

child.send(.dismiss)                    // nothing presented locally…
#expect(parent.presentedSheet == nil)   // …so it bubbles up
```

Run the package's own suite with `swift test`.

## Design decisions

The rationale — including the alternatives that were considered and rejected —
lives in the host repository's Architecture Decision Records:

- [ADR-0006](../docs/adr/0006-routes-as-values-with-a-destination-registry.md):
  routes as values with a destination registry (versus a central route enum, and
  versus closure-based destinations).
- [ADR-0007](../docs/adr/0007-wireframe-owns-presentation.md): the wireframe owns
  all presentation; modals nest as child wireframes.
- [ADR-0011](../docs/adr/0011-extract-wireframe-as-its-own-package.md): why this
  is a separate package rather than a folder or a target.

If this package ever moves to its own repository, those records should travel
with it.
