# ``Wireframe``

A domain-agnostic app shell: the MVI store contract plus intent-based,
value-routed navigation for SwiftUI.

## Overview

Wireframe packages the generic core of an MVI + Clean Architecture app — the
pieces that know nothing about any particular domain:

- **The MVI contract**: ``Store`` (a `State` the view renders, an `Intent`
  vocabulary, one synchronous `send(_:)`), plus ``PreviewStore`` so any screen
  can be previewed with fixed state and no wiring.
- **Navigation as intents over route values**: screens are described by small
  `Hashable` ``Route`` values saying *what* to show, never *how*. The caller
  picks the presentation (`push` / `sheet` / `present` / `alert`) through
  ``RouterIntent``; the destination never knows which was used.
- **The wireframe**: ``WireframeView`` owns every presentation container — the
  `NavigationStack`, the sheet, the fullscreen cover and the alert — and
  resolves routes through a ``DestinationRegistry`` at presentation time.
  Every modal it presents is a **child wireframe** with its own
  ``AppRouter``, so modals get their own stack, modals and alerts, and
  `dismiss` bubbles up the parent chain.
- **A session gate**: ``SessionStore``, an observable authenticated/expired
  flag the app root can switch on.

The package depends only on SwiftUI and Observation. Because it is a separate
package, the dependency is one-way by construction: the kit can never reach
into an app's domain, and it drops into any app as-is.

See <doc:AdoptingWireframe> for the end-to-end recipe.

## Topics

### Getting started

- <doc:AdoptingWireframe>

### The MVI contract

- ``Store``
- ``PreviewStore``

### Routing

- ``Router``
- ``RouterIntent``
- ``Route``
- ``AnyRoute``
- ``AppRouter``
- ``AlertContent``

### Presenting

- ``WireframeView``
- ``DestinationRegistry``

### Session

- ``SessionStore``
