# Agent Guide: Replicating This Architecture

Instructions for an AI coding agent asked to scaffold a **new** iOS app using the
same architecture as this repository: Clean Architecture (Domain / Data /
Presentation) with MVI (Model-View-Intent) as the per-screen pattern, in Swift and
SwiftUI, using async/await, actors, and the Observation framework. Read this file
top to bottom before writing any code; it is a recipe, not a reference to copy files
from.

Do not just copy this repository's `User`/list-detail-modal sample — rebuild the
same *structure* around whatever domain the user actually asked for.

## 1. Non-negotiable constraints

- **Language/UI**: Swift 6, SwiftUI only (no UIKit unless the user asks).
- **State observation**: the `Observation` framework (`@Observable`), never
  `ObservableObject` + `@Published`.
- **Concurrency**: `async/await` at every layer boundary; `actor` for any shared
  mutable state (in-memory caches, mock data sources); `Sendable` on every type or
  protocol that crosses an `await` boundary; `@MainActor` on every Store and Router.
- **Testing**: the **Swift Testing** framework (`import Testing`, `@Test`,
  `#expect`), not XCTest, unless the user explicitly asks for XCTest.
- **Package layout**: a single Swift Package with `Domain`, `Data`, `Presentation`,
  and `App` targets, wired exactly as in §3. This is what makes the Dependency Rule
  compiler-enforced instead of a convention someone can silently break.
- **Brevity**: keep every file small and single-purpose. One feature's `State` +
  `Intent` + `Store` belong in one file (`<Feature>Feature.swift`); its view in a
  sibling `<Feature>View.swift`. Do not add abstractions (generic repositories,
  event buses, DI frameworks) the current feature set doesn't need.
- **English**: all code, comments, and docs in English regardless of the
  conversation language.

## 2. Before writing code, ask (don't assume)

If the user hasn't specified them, ask directly rather than guessing:
- What is the app's domain/subject (to-do list, expenses, recipes, ...)?
- How many screens, and which navigation is push vs. modal?
- Does it need real networking, or is a mocked/in-memory data source acceptable for
  a sample? (Real backends need real error handling, auth, pagination — say so if
  the user wants that; don't silently under- or over-build.)

## 3. Package.swift skeleton

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "<AppName>",
    platforms: [.iOS(.v17), .macOS(.v14)], // macOS target lets `swift build`/`swift test` run without a simulator
    products: [
        .library(name: "Domain", targets: ["Domain"]),
        .library(name: "Data", targets: ["Data"]),
        .library(name: "Presentation", targets: ["Presentation"])
    ],
    targets: [
        .target(name: "Domain"),
        .target(name: "Data", dependencies: ["Domain"]),
        .target(name: "Presentation", dependencies: ["Domain"]),          // never depends on Data
        .testTarget(name: "DomainTests", dependencies: ["Domain"]),
        .testTarget(name: "DataTests", dependencies: ["Data", "Domain"]),
        .testTarget(name: "PresentationTests", dependencies: ["Presentation", "Domain"])
    ]
)
```

Add `.macOS(.v14)` even though the target is an iOS app: it lets `swift build` /
`swift test` run on any machine without booting a simulator, which is how you (the
agent) verify Domain/Data/Presentation. Guard any UIKit-only SwiftUI modifier
(`.keyboardType`, `.textInputAutocapitalization`, ...) with `#if os(iOS)` so the
macOS build target still compiles.

Do **not** add a fourth `executableTarget` for the app itself — see §6. The `App`
target that actually runs on a simulator is declared separately, in `project.yml`,
and depends on this package's three library products.

## 4. Build order (follow this sequence; don't jump ahead)

1. **Domain first, always.** Entities (plain `Sendable` `Equatable` `Codable`
   structs) → repository protocols (`Sendable`, `async throws` methods only) → use
   case protocols + `Default...` structs. A use case that just forwards to the
   repository is fine; add real logic (validation, combining calls) only where the
   business actually requires it — don't invent rules the user didn't ask for.
2. **Data second.** DTOs (`internal`, `Codable`, with `toDomain()`) → data source
   protocols + `actor` implementations (mock/in-memory is fine for a sample; say so
   in the README) → a repository struct implementing the Domain protocol, composing
   the data sources. Keep DTOs and data sources `internal` — only the repository
   type (or a `static func live()` factory on it) needs to be `public`.
3. **Presentation third**, per feature, one `<Feature>Feature.swift` containing:
   - `State: Equatable, Sendable` — everything the view reads, nothing else.
   - `Intent` — every user action and lifecycle event as an enum case.
   - `@Observable @MainActor final class <Feature>Store: Store` — constructor
     takes use case protocols (never the repository, never Data types) plus an
     `AppRouter` if the feature navigates. `send(_:)` is synchronous; async work is
     wrapped in `Task { }`.
   Also build once, shared across features: `Core/Store.swift` (the
   `Store<State, Intent>` protocol) and `Core/AppRouter.swift` (see §5).
4. **App fourth.** `CompositionRoot` (wires concrete Data types to Domain protocols,
   one `make<Feature>Store` factory per feature) and the `@main App` struct
   (`@State private var router = AppRouter()`, builds the root view from
   `CompositionRoot`) in `Sources/App`, plus the `project.yml` that turns those
   files into a real, simulator-runnable Xcode target (see §6).
5. **Tests alongside each layer**, not at the end — write the test target for a
   layer right after building it, per §8.

## 5. Navigation recipe

Keep navigation out of every feature's `State`. One `AppRouter`:

```swift
@Observable @MainActor
public final class AppRouter {
    public enum Route: Hashable { /* one case per pushable destination */ }
    public enum Sheet: Identifiable { /* one case per modal; var id: String */ }
    public var path: [Route] = []
    public var presentedSheet: Sheet?
    public func push(_ route: Route) { path.append(route) }
    public func present(_ sheet: Sheet) { presentedSheet = sheet }
    public func dismissSheet() { presentedSheet = nil }
}
```

A Store's `send(_:)` calls `router.push`/`router.present` directly for navigation
Intents — it never returns a "navigation event" for the View to interpret. The root
view binds `NavigationStack(path: $router.path)` with `.navigationDestination(for:
AppRouter.Route.self)` for **push**, and `.sheet(item: $router.presentedSheet)` for
**modal**. The task must include at least one of each — if the user's feature list
doesn't naturally produce both, add a minimal second screen/modal that does (e.g. an
"About" sheet, or a settings row) rather than skipping the requirement.

## 6. The App target: generate it with XcodeGen, don't hand-author a `.xcodeproj`

`Sources/App` (the `@main` App struct and `CompositionRoot`) needs to become a real
Xcode "iOS App" target to be installable and runnable on a simulator — an SPM
`executableTarget` compiles against the iOS Simulator SDK but never produces an
installable `.app` bundle (no Info.plist generation tied to an app product, no code
signing for an app product type, etc.). Do not attempt to hand-write a
`.xcodeproj`/`pbxproj` file yourself; it is a fragile, undocumented binary-ish
format and easy to corrupt. Instead:

1. Check for [XcodeGen](https://github.com/yonaskolb/XcodeGen): `which xcodegen`.
   If missing and Homebrew is available and working, `brew install xcodegen`. If
   Homebrew itself is broken (common after a macOS upgrade until the user updates
   it), ask the user to update/fix Homebrew rather than working around it.
2. Write `project.yml` at the repository root:

```yaml
name: <AppName>
options:
  bundleIdPrefix: com.example
  deploymentTarget:
    iOS: "17.0"
packages:
  <AppName>Kit:
    path: .
targets:
  App:
    type: application
    platform: iOS
    deploymentTarget: "17.0"
    sources:
      - path: Sources/App
    dependencies:
      - package: <AppName>Kit
        product: Domain
      - package: <AppName>Kit
        product: Data
      - package: <AppName>Kit
        product: Presentation
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.example.<appname>
        GENERATE_INFOPLIST_FILE: YES
        INFOPLIST_KEY_UILaunchScreen_Generation: YES
        INFOPLIST_KEY_UIApplicationSceneManifest_Generation: YES
        SWIFT_VERSION: "6.0"
```

3. Run `xcodegen generate` to produce `<AppName>.xcodeproj`. Do **not** commit the
   generated project — gitignore `*.xcodeproj/` and commit `project.yml` instead,
   so the project can never drift from the package and is regenerated on demand.
4. Remove any `executableTarget`/`.executable` product named `App` from
   `Package.swift` if one exists (see §3) — a native Xcode target and an SPM
   executable product sharing the name `App` in the same workspace is a naming
   collision waiting to happen, and only one of them can actually run on a
   simulator.

Verify the result end to end rather than assuming the config is right:

```bash
xcodebuild build -project <AppName>.xcodeproj -scheme App -destination 'id=<simulator-udid>'
xcrun simctl boot <simulator-udid>              # if not already booted
xcrun simctl install <simulator-udid> <DerivedData path from the build log>/<AppName>.app
xcrun simctl launch <simulator-udid> com.example.<appname>
xcrun simctl io <simulator-udid> screenshot /tmp/screenshot.png
```

Read the screenshot back (e.g. with a file-reading tool that can view images) to
confirm the UI actually rendered — a launch with no crash is not proof the screen
looks right. `xcrun simctl` has no built-in tap/touch injection, so exercising push
and modal navigation via taps from an agent generally isn't possible without extra
tooling (Accessibility-permissioned UI scripting, or a UI test target); rely on the
unit tests from §8 to cover navigation logic, and be explicit in the README about
what was and wasn't verified through the simulator versus through tests.

## 7. Composition Root recipe

One `struct CompositionRoot` in the `App` target — the only file allowed to import
`Domain`, `Data`, and `Presentation` together:

```swift
@MainActor
struct CompositionRoot {
    private let repository: SomeRepository = DefaultSomeRepository.live()
    func make<Feature>Store(router: AppRouter) -> <Feature>Store {
        <Feature>Store(someUseCase: DefaultSomeUseCase(repository: repository), router: router)
    }
}
```

If a change made in one feature must show up in another (e.g. a favorite toggled
in the detail screen, a user added from the modal form), don't wire callbacks
between stores. The repository exposes an `AsyncStream` of the data
(`observeUsers()`), and any screen that keeps that data visible subscribes to it
from its own store when the `.onAppear` intent arrives (see
`UserListStore.startObservingIfNeeded`). One source of truth, zero cross-feature
coupling — and no Combine, NotificationCenter, or event bus either.

## 8. Testing recipe

Mirror the module graph — one test target per source target, each faking only the
layer directly below it, never the real implementation two layers down:

- **DomainTests** fake the repository protocol (an `actor FakeXRepository:
  XRepository`, since the protocol requires `Sendable` and tests call it from async
  contexts). Test business rules: validation, error propagation, pass-through
  behavior.
- **DataTests** fake the data source protocol(s), use the *real* repository
  implementation and the *real* local-store actor. Test merge/caching policy: does
  a locally-set flag survive a refetch, is sorting correct, does a missing id throw.
- **PresentationTests** fake every use case protocol directly (plain structs with a
  `resultToReturn`/`errorToThrow` property are enough — no repository involved).
  Test that each `Intent` produces the right `State` transition and the right
  `AppRouter` call. `@MainActor` the test suite since Stores are `@MainActor`.

Because `send(_:)` kicks off `Task { }` and returns immediately, tests need to wait
for the async work to land. Add one small shared helper instead of `Task.sleep` in
every test:

```swift
@MainActor
func waitUntil(timeout: Duration = .seconds(1), _ condition: () -> Bool) async throws {
    let deadline = ContinuousClock.now + timeout
    while !condition(), ContinuousClock.now < deadline {
        try await Task.sleep(for: .milliseconds(5))
    }
}
```

Poll on a condition that is only true *after* the async work completes (e.g.
`!state.users.isEmpty`), never on something like `isLoading == false` that can
already be true before the work even starts — that race produces flaky green tests
that pass for the wrong reason.

Use `#expect(throws: SomeError.self)` for the type-only check; use `#expect(throws:
someValue)` only when the error type is `Equatable`.

## 9. Verifying your own work (do this before reporting done)

```bash
swift build          # compiles Domain/Data/Presentation for macOS — fast inner-loop check
swift test           # runs every test target with Swift Testing
```

If a full Xcode installation is available (check with `xcodebuild -version`; on
some machines only Command Line Tools are active even though Xcode.app is
installed — try `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
xcodebuild -version`), also compile against a real iOS Simulator SDK to catch
iOS-only API usage that a macOS-only `swift build` can't:

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild build -project <AppName>.xcodeproj -scheme App -destination 'id=<simulator-udid>'
# list available simulators/udids with:
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun simctl list devices available
```

Note the `import Testing` module is only available through a full Xcode toolchain,
not bare Command Line Tools — if `swift test` fails with "no such module 'Testing'",
check `xcode-select -p` and retry with `DEVELOPER_DIR` pointed at Xcode.app as
above, rather than switching the machine's default toolchain (which is a
system-wide change you should not make without asking).

Once XcodeGen has produced `<AppName>.xcodeproj` (§6), that same `xcodebuild`
invocation produces a real, installable `<AppName>.app` — install and launch it with
`xcrun simctl install`/`launch` and screenshot it with `xcrun simctl io ... screenshot`
to confirm it actually renders (§6) before telling the user it runs on the
simulator. Don't claim the app launches successfully without having actually
launched and screenshotted it in the same session.

## 10. Documentation to produce alongside the code

Every replication of this architecture should also produce:
- **README.md** — what the sample app does, project/module layout, how to build
  and test it, how to open it in Xcode.
- **ARCHITECTURE.md** — the same kind of walkthrough as this repository's
  `ARCHITECTURE.md`: explain Domain/Data/Presentation and the Dependency Rule, then
  MVI (Model/Intent/Store loop) with real snippets from the files you just wrote,
  then navigation-as-a-side-effect, then the composition root, then concurrency
  choices, then the testing strategy. Pull code excerpts from the actual generated
  files, not from this guide.
- This file itself, if the user wants to replicate the pattern *again* later —
  otherwise it's optional for a one-off app.

## 11. Common mistakes to avoid

- Putting navigation state inside a feature's `State` instead of `AppRouter`.
- Letting `Presentation` depend on `Data` "just this once" — it breaks the whole
  point of the module graph; add a use case instead.
- Doing async work directly inside `send(_:)` instead of wrapping it in `Task { }`
  — this makes `send` async and defeats the synchronous View → Store call contract.
- Using `ObservableObject`/`@Published` — this is a Clean/MVI-with-Observation
  project; use `@Observable`.
- Writing repository/use-case fakes as plain classes with `var` properties when the
  protocol requires `Sendable` — use an `actor` fake, or a `struct`/`final class ...
  @unchecked Sendable` only when you're certain the test never mutates it
  concurrently.
- Forgetting `#if os(iOS)` around UIKit-bridged SwiftUI modifiers, breaking the
  macOS sanity build.
