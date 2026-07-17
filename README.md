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
Package.swift    Domain, Data, Presentation libraries + their test targets
project.yml      XcodeGen spec for the native iOS App target
Sources/
  Domain/        entities, repository protocols, use cases       (no dependencies)
  Data/          DTOs, data sources, repository implementations  (depends on Domain)
  Presentation/  MVI State/Intent/Store + SwiftUI views          (depends on Domain only)
  App/           composition root + @main entry point            (built by the Xcode target, not by Package.swift)
Tests/
  DomainTests/         use cases tested against a fake repository
  DataTests/           repository tested against fake data sources
  PresentationTests/   stores tested against fake use cases
```

The dependency graph (`Presentation` never imports `Data`) is enforced by
`Package.swift`, not just by convention — see [ARCHITECTURE.md](ARCHITECTURE.md)
for why that matters.

`Sources/App` is compiled by a real Xcode "iOS App" target (see below), not by
`Package.swift`: an SPM `executableTarget` can compile against the iOS Simulator
SDK but cannot produce an installable `.app` bundle, which the app actually
needs to run on a simulator.

## Build & test

Requires Swift 6 (Xcode 16+ or a matching command-line toolchain).

```bash
swift build   # builds the Domain, Data and Presentation libraries for macOS
swift test    # runs all three test targets (21 tests) with Swift Testing
```

Both commands also work scoped to one target, e.g. `swift test --filter
DomainTests`.

## Running the app on the Simulator

The Xcode project is generated from [`project.yml`](project.yml) with
[XcodeGen](https://github.com/yonaskolb/XcodeGen) rather than committed, so it
never goes stale relative to the package:

```bash
brew install xcodegen   # once
xcodegen generate       # produces MVIExample.xcodeproj
```

Then either open `MVIExample.xcodeproj` in Xcode, select the **App** scheme and
an iPhone simulator, and Run — or drive it entirely from the command line:

```bash
xcrun simctl list devices available                       # find a simulator id
xcodebuild build -project MVIExample.xcodeproj -scheme App -destination 'id=<simulator-udid>'
xcrun simctl boot <simulator-udid>
xcrun simctl install <simulator-udid> <path-to-built>/MVIExample.app
xcrun simctl launch <simulator-udid> com.example.mviexample
```

`MVIExample.xcodeproj` is gitignored (regenerate it with `xcodegen generate`
whenever you pull changes to `project.yml` or add new source files).

## Requirements

- Swift 6 / Xcode 16+
- iOS 17+ (uses the `Observation` framework and `NavigationStack`)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) to generate the runnable
  Xcode project (`brew install xcodegen`)
