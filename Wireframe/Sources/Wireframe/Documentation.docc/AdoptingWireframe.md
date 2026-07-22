# Adopting Wireframe in an App

The end-to-end recipe: routes, a registry, wireframes, and flows.

## Overview

An app plugs into the kit with four moves. The examples below use a `User`
domain, but nothing in the kit knows or cares.

### 1. Describe screens as route values

Each feature declares a small `Hashable` value conforming to ``Route``. It says
*what* to show — the payload — never *how*:

```swift
public nonisolated struct UserDetailRoute: Route {
    public let user: User
}
```

`nonisolated` matters under main-actor default isolation: routes are inert
values, and keeping them (and their synthesized `Hashable`) out of any actor
lets them travel through `NavigationPath` freely.

### 2. Register each route with its view, once

The app's composition root fills a ``DestinationRegistry``. Presentation mode
is *not* part of the registration, and each builder receives the ``Router`` of
the wireframe that will present it — so a screen inside a modal acts on that
modal's context, not on the tab below it:

```swift
let registry = DestinationRegistry()
registry.register(UserDetailRoute.self) { route, router in
    UserDetailView(store: UserDetailStore(
        user: route.user,
        flow: RelatedUserFlow(router: router)
    ))
}
```

### 3. Wrap each root screen in a wireframe

``WireframeView`` owns the `NavigationStack`, the sheet, the fullscreen cover
and the alert. Give each independent navigation context (each tab, typically)
its own ``AppRouter``:

```swift
TabView {
    WireframeView(router: tabRouter, registry: registry) {
        UserListView(store: makeUserListStore(router: tabRouter))
    }
}
```

Keep the routers in the composition root, not in the view tree: navigation
state then survives tab switches — and even a ``SessionStore`` expiry, because
logging back in re-binds the same routers and restores every stack and modal.

Modals need no extra work: any route sent with `.sheet` or `.present` is
wrapped in a **child wireframe** automatically (its own ``AppRouter`` with a
`parent` link), which is what gives modals their own navigation and makes
`.dismiss` bubble to whoever presented them.

### 4. Navigate by sending intents — ideally from flows

Anything holding a ``Router`` can navigate:

```swift
router.send(.push(UserDetailRoute(user: user)))
router.send(.sheet(AddUserRoute()))
router.send(.alert(AlertContent(title: user.name, message: user.email)))
router.send(.dismiss)
```

The recommended shape on top: stores report *semantic events* to a per-feature
flow protocol (`didSelectUser(_:)`, `didFinish()`), and small flow structs
owned by the composition translate them into router intents. The flow — not
the store, not the view — picks the destination and the mode, which is what
lets the same screen navigate differently per context.

## Why routes are values

Because a ``Route`` is data, not a view builder:

- `popTo` works by equality (``AppRouter`` keeps a mirror of the pushed
  routes beside the opaque `NavigationPath`).
- A route can be **constructed from a URL**, so deep links reuse the exact
  same navigation path as in-app flows with zero extra presentation code.
- Tests assert *where* navigation went (`router.routes`,
  `router.presentedSheet`) instead of "something was presented".

The one type-erasure cost lives in ``DestinationRegistry`` (a map of
heterogeneous view builders cannot be typed); a screen boundary is where
`AnyView` costs nothing.

## Testing

``Router`` is a protocol, so store/flow tests either spy on intents or drive a
real ``AppRouter`` and assert on its state:

```swift
let parent = AppRouter()
parent.send(.sheet(EditorRoute()))
let child = AppRouter(parent: parent)

child.send(.dismiss)                    // nothing presented locally…
#expect(parent.presentedSheet == nil)   // …so it bubbles up
```

``PreviewStore`` fills the same role for views: fixed state, no-op intents,
zero wiring behind a `#Preview`.
