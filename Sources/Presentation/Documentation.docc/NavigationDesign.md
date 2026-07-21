# Navigation

Split into policy (flows) and mechanism (the router), with presentation-agnostic
destination views.

## Overview

Navigation is a side effect, not screen state: putting a `route` field in every
`State` conflates "what does this screen look like" with "where does the app go
next" and forces every feature to know navigation types it doesn't own. Instead it
is split into two layers:

```
Store ──semantic event──▶ Flow   (policy: what comes next)
                            │
                            ▼
                          Router (mechanism: push / sheet / present / alert)
                            │
              WireframeView + DestinationRegistry (presentation)
```

## Flows are the policy

Each feature owns a protocol in domain language — ``UserListFlow`` with
`didSelectUser(_:)`, ``AddUserFlow`` with `didFinish()` — and its store only
reports *what happened*, never where it leads. Concrete flows (in
`Sources/Presentation/Flows`) knit features together; the features never know each
other. The composition root decides which flow each screen gets, so the **same**
``UserListView`` behaves differently per context with zero feature changes:

- ``BrowseUsersFlow`` (the tabs): selecting pushes a detail, adding opens a sheet,
  the picker covers fullscreen.
- ``PickUserFlow`` (a modal): selecting shows an alert instead of navigating.

Store tests use a flow spy; route/mode assertions live in the flow tests.

## The Router is the mechanism

``Router`` is a closed vocabulary of intents behind a single entry point,
mirroring ``Store``. Flows depend on the protocol, so they are tested against a
real ``AppRouter`` or a spy:

```swift
public enum RouterIntent {
    case push(any Route)      // the caller picks the presentation;
    case sheet(any Route)     // the destination never knows which
    case present(any Route)   // fullscreen cover
    case alert(AlertContent)
    case pop, popToRoot, popTo(any Route), dismiss
}
```

Destinations are described by **route values, not view builders**: each feature
declares a small ``Route``-conforming struct saying *what* to show, never *how*.
``DestinationRegistry`` (filled once by the composition root) maps each route type
to its view, and ``WireframeView`` resolves routes through it at presentation time.
Because resolution is independent of the mode, **the same route can be pushed or
presented modally interchangeably**. Views carry no `NavigationStack` and no
dismiss logic.

Because routes are values they stay comparable — `popTo` works by equality — and
could be made `Codable` for deep links. ``AppRouter`` keeps a `routes` mirror
beside the opaque `NavigationPath`, reconciled when the user pops interactively.
The registry is the one deliberate `AnyView` in the app: a map of heterogeneous
view builders cannot be typed, and a screen boundary is where erasure costs
nothing.

## Wireframes nest

Every modal a ``WireframeView`` presents is wrapped in a child wireframe with its
own `AppRouter(parent:)` — its own stack, modals, and alerts. `dismiss` bubbles up
the parent chain, so a screen deep inside a modal closes it without knowing who
presented it. Registry builders receive the presenting wireframe's router, which
keeps every destination acting on its own navigation context. The related-users
feature nests two levels — detail → related-users list → multi-select editor — and
needs **no callbacks up the chain**: the multi-select editor mutates the observable
`@Model` relationship through a use case, and the list and detail behind it
re-render on their own.

## Wireframes multiply

The app is a login gate (``SessionStore`` + `RootView`) over a `TabView` where each
tab is its own wireframe: independent navigation state per tab, kept alive across
tab switches — and across session expiries, because the routers live in the
composition root, not the view tree. When the session expires, the whole content is
covered by the login screen; logging back in restores every stack and modal exactly
as they were.

## Deep links: where routes-as-values pay off

An incoming URL is parsed into a ``DeepLink`` value, and ``DeepLinkCoordinator``
turns it into **the very same route value an in-app flow would build** —
`mviexample://user/<uuid>` resolves the id (the one repository read) and sends
`.push(UserDetailRoute(user:))` to the tab's router. The registry and wireframe
present it with **no deep-link-specific presentation code at all**. This is the
concrete payoff of routes being values, not view builders: a route can be
*constructed from a URL*, which a closure-based destination cannot. A link arriving
while logged out is held pending and applied on login, so the session gate never
drops it.

## Topics

- ``Router``
- ``RouterIntent``
- ``AppRouter``
- ``Route``
- ``WireframeView``
- ``DestinationRegistry``
- ``SessionStore``
- ``DeepLink``
- ``DeepLinkCoordinator``
- ``UserListFlow``
- ``UserDetailFlow``
