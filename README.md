# MVI Example

A minimal iOS sample app demonstrating **Clean Architecture (Domain / Data /
Presentation)** combined with **MVI (Model-View-Intent)**, built with Swift 6,
SwiftUI, the Observation framework, and structured concurrency.

The app itself is intentionally small — a user directory with a list, a detail
screen reached by **push navigation**, and an "add user" form reached by a
**modal sheet** — so the architecture, not the feature set, is the point.

For a full explanation of the architecture with code excerpts, see
**[ARCHITECTURE.md](ARCHITECTURE.md)**. To have an AI agent replicate this same
pattern for a different app, see **[AGENT_GUIDE.md](AGENT_GUIDE.md)**.

## What it does

- **User List** (`Sources/Presentation/Features/UserList`): loads users
  asynchronously, pull-to-refresh, tap a row to push to detail, tap "Add" to
  present a modal.
- **User Detail** (`Sources/Presentation/Features/UserDetail`, pushed): shows a
  user and toggles their favorite status with an optimistic UI update.
- **Add User** (`Sources/Presentation/Features/AddUser`, presented as a sheet): a
  form that validates input through a Domain use case before saving.

Networking is simulated (`MockRemoteUserDataSource`, an `actor` with an artificial
delay) so the sample runs with no backend and no configuration.

## Project layout

```
Package.swift
Sources/
  Domain/        entities, repository protocols, use cases       (no dependencies)
  Data/          DTOs, data sources, repository implementations  (depends on Domain)
  Presentation/  MVI State/Intent/Store + SwiftUI views          (depends on Domain only)
  App/           composition root + @main entry point            (depends on all three)
Tests/
  DomainTests/         use cases tested against a fake repository
  DataTests/           repository tested against fake data sources
  PresentationTests/   stores tested against fake use cases
```

The dependency graph (`Presentation` never imports `Data`) is enforced by
`Package.swift`, not just by convention — see [ARCHITECTURE.md](ARCHITECTURE.md)
for why that matters.

## Build & test

Requires Swift 6 (Xcode 16+ or a matching command-line toolchain).

```bash
swift build   # builds Domain, Data, Presentation and App for macOS
swift test    # runs all three test targets (21 tests) with Swift Testing
```

Both commands also work scoped to one target, e.g. `swift test --filter
DomainTests`.

If a full Xcode installation is available, you can additionally compile against a
real iOS Simulator SDK (catches iOS-only API usage that the macOS build can't):

```bash
xcrun simctl list devices available          # find a simulator id
xcodebuild build -scheme App -destination 'id=<simulator-udid>'
```

## Running the app

Open `Package.swift` directly in Xcode (File > Open...), select the **App**
scheme and an iPhone simulator, then Run.

Note: as a Swift Package `executableTarget`, `App` is verified to compile
correctly against the iOS Simulator SDK, but an SPM executable target does not by
itself produce a distributable, installable `.app` bundle (icon, entitlements,
etc.) the way a real Xcode "iOS App" target does. To ship or distribute the app,
add this package as a local Swift Package dependency of a proper Xcode
application target and move `Sources/App`'s two files into it.

## Requirements

- Swift 6 / Xcode 16+
- iOS 17+ (uses the `Observation` framework and `NavigationStack`)
