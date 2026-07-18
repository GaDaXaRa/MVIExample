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
Domain            ← no target dependencies (imports SwiftData for @Model)
Data              ← depends on Domain
Presentation      ← depends on Domain (never Data)
App               ← depends on all three (composition root)
```

`Presentation` cannot `import Data`: it isn't a declared dependency, so it is a
build error, not a code-review comment. A screen only knows business concepts
(`User`, a use case) and never *how* they are fetched or stored.

## Topics

### Architecture

- <doc:CleanArchitecture>
- <doc:TheMVILoop>
- <doc:NavigationDesign>
- <doc:Composition>
- <doc:Testing>

### The MVI contract

- ``Store``
- ``PreviewStore``

### Navigation

- ``Router``
- ``RouterIntent``
- ``AppRouter``
- ``Route``
- ``AnyRoute``
- ``AlertContent``
- ``WireframeView``
- ``DestinationRegistry``
- ``SessionStore``

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
