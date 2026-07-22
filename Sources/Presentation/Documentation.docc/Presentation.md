# ``Presentation``

The MVI layer: how every screen manages its state and how the app navigates.

## Overview

This project combines two ideas that operate at different scopes and compose
naturally:

- **Clean Architecture** decides how the *code is layered* and which way
  dependencies point — the `Domain`, `Data`, and `Presentation` modules.
- **MVI (Model-View-Intent)** decides how *each screen* manages its state — the
  pattern used by every feature inside this `Presentation` module.

The sample app (a small user directory behind a login gate, with tabs, nested
modals, and related-user management) exists only as a vehicle to demonstrate the
architecture end to end. Each article below explains one pillar and points at the
real source.

The module graph, enforced by the compiler through `Package.swift`:

```
Wireframe (pkg)   ← domain-agnostic MVI + navigation kit (its own SPM package)
Domain            ← no target dependencies (imports SwiftData for @Model)
Data              ← depends on Domain
Presentation      ← depends on Domain + Wireframe (never Data)
App               ← depends on all of the above (composition root)
```

`Presentation` cannot `import Data`: it isn't a declared dependency, so it is a
build error, not a code-review comment. A screen only knows business concepts
(`User`, a use case) and never *how* they are fetched or stored. The generic
core (`Store`, `Router`, `WireframeView`, `DestinationRegistry`, `SessionStore`)
lives in the separate **Wireframe** package, so it physically cannot reach back
into any app layer and could be reused by another app as-is.

## Topics

### Architecture

- <doc:CleanArchitecture>
- <doc:TheMVILoop>
- <doc:NavigationDesign>
- <doc:Composition>
- <doc:Testing>

### Deep linking

- ``DeepLink``
- ``DeepLinkCoordinator``

### Features

- ``UserListStore``
- ``UserDetailStore``
- ``AddUserStore``
- ``LoginStore``

### Flows

- ``UserListFlow``
- ``UserDetailFlow``
- ``AddUserFlow``
- ``LoginFlow``
