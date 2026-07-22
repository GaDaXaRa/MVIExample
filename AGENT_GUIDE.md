# Agent Guide: Replicating This Architecture

Instructions for an AI coding agent asked to scaffold a **new** iOS app using the
same architecture as this repository: Clean Architecture (Domain / Data /
Presentation) with MVI (Model-View-Intent) as the per-screen pattern, SwiftData as
the single source of truth, and the reusable **Wireframe** package for navigation —
in Swift 6.2, SwiftUI, async/await and the Observation framework. Read this file
top to bottom before writing any code; it is a recipe, not a reference to copy
files from.

Do not just copy this repository's `User`/list-detail-modal sample — rebuild the
same *structure* around whatever domain the user actually asked for.

## 1. Non-negotiable constraints

- **Language/UI**: Swift 6.2, SwiftUI only (no UIKit unless the user asks).
- **State observation**: the `Observation` framework (`@Observable`), never
  `ObservableObject` + `@Published`.
- **Concurrency**: main-actor **by default** — every target sets
  `.defaultIsolation(MainActor.self)` (SE-0466), so stores, routers, flows and
  the repository contracts carry no `@MainActor` annotations. Concurrency is
  opt-in and explicit: `actor` for a real boundary (the remote data source),
  `nonisolated` for inert values that must cross isolation (DTOs, `Route`
  conformers). `async/await` at every layer boundary.
- **Persistence/model**: **SwiftData**. The Domain entity is a `@Model` class —
  one type is simultaneously the schema, the persisted row, the observable object
  views react to, and the navigation payload. Views read collections with
  `@Query`; the repository exposes **mutations plus at most a point read** (for
  deep links), never list reads.
- **Navigation**: the **Wireframe** package (see §5). Never hand-roll
  `NavigationStack` state inside features; destination views must be
  presentation-agnostic.
- **Testing**: the **Swift Testing** framework (`import Testing`, `@Test`,
  `#expect`), not XCTest, unless the user explicitly asks for XCTest.
- **Package layout**: the domain-agnostic kit lives in its own local SPM package
  (`Wireframe/`); the app is a second package with `Domain`, `Data`,
  `Presentation` targets plus an XcodeGen-generated `App` target, wired exactly
  as in §3/§6. This is what makes the Dependency Rule compiler-enforced instead
  of a convention someone can silently break.
- **Localization**: a String Catalog (`Localizable.xcstrings`) in the App target.
  SwiftUI text in package views resolves from `Bundle.main` automatically; only
  Domain error messages need `String(localized:)` and runtime keys need
  `LocalizedStringKey(...)`.
- **Brevity**: keep every file small and single-purpose. One feature's `State` +
  `Intent` + `Store` (+ its `Route` and `Flow` protocol) belong in one file
  (`<Feature>Feature.swift`); its view in a sibling `<Feature>View.swift`. Do
  not add abstractions the current feature set doesn't need.
- **English**: all code, comments, and docs in English regardless of the
  conversation language.

## 2. Before writing code, ask (don't assume)

If the user hasn't specified them, ask directly rather than guessing:
- What is the app's domain/subject (to-do list, expenses, recipes, ...)?
- How many screens; which are pushed, which are modal; tabs or single stack?
- Is there a session/login gate? Deep links? Which languages?
- Does it need real networking, or is a mocked/in-memory remote acceptable for a
  sample? (Real backends need real error handling, auth, pagination — say so if
  the user wants that; don't silently under- or over-build.)

## 3. Package skeleton

Bring the **Wireframe** package along unchanged — copy this repository's
`Wireframe/` directory into the new repo (or depend on it remotely if it has
been published). It is domain-agnostic by construction and needs no edits.

The app package:

```swift
// swift-tools-version: 6.2
import PackageDescription

let mainActorByDefault: [SwiftSetting] = [.defaultIsolation(MainActor.self)]

let package = Package(
    name: "<AppName>",
    platforms: [.iOS(.v17), .macOS(.v14)], // macOS lets `swift build`/`swift test` run without a simulator
    products: [
        .library(name: "Domain", targets: ["Domain"]),
        .library(name: "Data", targets: ["Data"]),
        .library(name: "Presentation", targets: ["Presentation"])
    ],
    dependencies: [
        .package(path: "Wireframe")
    ],
    targets: [
        .target(name: "Domain", swiftSettings: mainActorByDefault),
        .target(name: "Data", dependencies: ["Domain"], swiftSettings: mainActorByDefault),
        .target(
            name: "Presentation", // never depends on Data
            dependencies: ["Domain", .product(name: "Wireframe", package: "Wireframe")],
            swiftSettings: mainActorByDefault
        ),
        .testTarget(name: "DomainTests", dependencies: ["Domain"], swiftSettings: mainActorByDefault),
        .testTarget(name: "DataTests", dependencies: ["Data", "Domain"], swiftSettings: mainActorByDefault),
        .testTarget(
            name: "PresentationTests",
            dependencies: ["Presentation", "Domain", .product(name: "Wireframe", package: "Wireframe")],
            swiftSettings: mainActorByDefault
        )
    ]
)
```

Guard any UIKit-only SwiftUI modifier (`.keyboardType`,
`.textInputAutocapitalization`, ...) with `#if os(iOS)` so the macOS build still
compiles. Do **not** add an `executableTarget` for the app itself — see §6.

## 4. Build order (follow this sequence; don't jump ahead)

1. **Domain first, always.**
   - The entity is a `@Model final class` (public `var`s, a `private(set)`
     stable `id: UUID`). Relationships need care: a self-referential or
     to-many relationship must declare its **inverse** with
     `@Relationship(deleteRule: .nullify, inverse: ...)` so deletes clean up
     referrers automatically.
   - The repository protocol is main-actor (the module default — no annotation)
     and covers **mutations only** (`refresh`, `add`, `set...`, `remove`) plus
     at most one point read (`entity(id:)`) for deep-link resolution. No list
     reads: views observe with `@Query`.
   - Use case protocols + `Default...` structs. A pass-through use case is
     fine; put real invariants (validation, no-self-relation, idempotence)
     here — they must hold regardless of caller.
2. **Data second.** A `nonisolated` DTO (`Codable`, `Sendable`) and a
   `nonisolated protocol` remote data source implemented by an `actor` (this is
   the app's one real concurrency boundary; only Sendable DTOs cross it). The
   repository works directly on SwiftData's `ModelContext` (`container.mainContext`);
   refresh **upserts** by stable id — the mock remote must return **fixed UUIDs**
   or every launch duplicates the seed rows in the persisted store. Never let a
   remote refresh clobber locally-set flags.
3. **Presentation third**, per feature, one `<Feature>Feature.swift` containing:
   - `nonisolated struct <Feature>Route: Route` if the screen is reachable from
     another one (routes are inert values; `nonisolated` keeps their synthesized
     `Hashable` out of the main actor).
   - `protocol <Feature>Flow` — the semantic events the store reports
     (`didSelectItem(_:)`, `didFinish()`), in domain language, never
     destinations. Give rarely-wired events default no-op implementations.
   - `State` (transient UI state only — loading/error; **not** the model data,
     which `@Query` provides) + `Intent` + `@Observable final class
     <Feature>Store: Store` whose `send(_:)` is synchronous (async work wrapped
     in `Task { }`). Data mutations call use cases directly; navigation-ish
     events go to the flow.
   - The view in `<Feature>View.swift`: owns its store via
     `@State private var store: any Store<State, Intent>`
     (`State(initialValue:)` in init), reads collections via `@Query`, sends
     intents, and uses `store.binding(_:send:)` for form fields. If one view
     serves several contexts, model the chrome/data variance as a
     `<Feature>Mode` enum with associated values (invalid combinations
     unrepresentable) and let the injected flow vary the behavior.
   Concrete flows live in `Presentation/Flows/` — a flow may know several
   features (knitting screens together is its job); features never know each
   other.
4. **App fourth.** `CompositionRoot` + `RootView` + the `@main` App struct in
   `Sources/App` (see §7), plus the `project.yml` that turns those files into a
   real, simulator-runnable Xcode target (see §6), plus the
   `Localizable.xcstrings` String Catalog.
5. **Tests alongside each layer**, not at the end — write the test target for a
   layer right after building it, per §8.

## 5. Navigation recipe (the Wireframe kit)

The kit provides `Store`, `PreviewStore`, `Route`/`AnyRoute`,
`Router`/`RouterIntent`/`AppRouter`, `AlertContent`, `WireframeView`,
`DestinationRegistry` and `SessionStore`. Read its DocC article *Adopting
Wireframe in an App* for details. The shape:

- **Route values** describe *what* to show; ``RouterIntent`` picks *how*
  (`push`/`sheet`/`present`/`alert`/`pop`/`popTo`/`dismiss`). The destination
  view never knows its presentation mode and must not contain a
  `NavigationStack` or dismiss logic of its own.
- **`DestinationRegistry`**: the composition root registers each route type
  with its view exactly once; builders receive the presenting wireframe's
  router.
- **`WireframeView`** wraps each root screen (each tab). Modals become child
  wireframes automatically; `dismiss` bubbles up the parent chain.
- **Stores never talk to the Router directly** — they report semantic events to
  their flow; the flow translates to router intents. Store tests use a flow
  spy; route/mode assertions live in flow tests.
- **Session gate**: keep `AppRouter`s in the composition root and switch
  `RootView` on `SessionStore.isAuthenticated` — navigation state then survives
  a session expiry and is restored on re-login.
- **Deep links**: parse the URL into a value enum (`DeepLink(url:)`), then a
  small coordinator resolves ids through the one repository point read and
  sends **the same route values** in-app flows use to the target tab's router.
  A link arriving while logged out is held pending and applied on login.
  Register the URL scheme in `project.yml` (see §6).

The task must include at least one push and one modal — if the user's feature
list doesn't naturally produce both, add a minimal second screen/modal that
does rather than skipping the requirement.

## 6. The App target: generate it with XcodeGen, don't hand-author a `.xcodeproj`

`Sources/App` needs to become a real Xcode "iOS App" target to be installable
and runnable on a simulator — an SPM `executableTarget` compiles against the
iOS Simulator SDK but never produces an installable `.app` bundle. Do not
attempt to hand-write a `.xcodeproj`; use [XcodeGen](https://github.com/yonaskolb/XcodeGen)
(`which xcodegen`; `brew install xcodegen` if missing — and if Homebrew itself
is broken, ask the user to fix it rather than working around it).

`project.yml` at the repository root:

```yaml
name: <AppName>
options:
  bundleIdPrefix: com.example
  developmentLanguage: en
  deploymentTarget:
    iOS: "17.0"
packages:
  <AppName>Kit:
    path: .
  Wireframe:
    path: Wireframe
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
      - package: Wireframe
        product: Wireframe
    # Explicit Info.plist (generated by XcodeGen) rather than
    # GENERATE_INFOPLIST_FILE: array keys like CFBundleURLTypes (deep links)
    # don't fit scalar INFOPLIST_KEY_ settings.
    info:
      path: Sources/App/Info.plist
      properties:
        CFBundleDisplayName: <App Name>
        CFBundleLocalizations: [en, es]
        UILaunchScreen: {}
        UIApplicationSceneManifest:
          UIApplicationSupportsMultipleScenes: false
        CFBundleURLTypes:
          - CFBundleURLName: com.example.<appname>
            CFBundleURLSchemes: [<appscheme>]
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.example.<appname>
        SWIFT_DEFAULT_ACTOR_ISOLATION: MainActor
        SWIFT_VERSION: "6.0"
```

Run `xcodegen generate`. Do **not** commit the generated project or the
generated `Info.plist` — gitignore `*.xcodeproj/` and `Sources/App/Info.plist`,
commit `project.yml`, regenerate on demand.

Verify end to end rather than assuming the config is right:

```bash
xcodebuild build -project <AppName>.xcodeproj -scheme App -destination 'platform=iOS Simulator,name=<device>'
xcrun simctl install <device> <path to built .app>
xcrun simctl launch <device> com.example.<appname>
xcrun simctl io <device> screenshot /tmp/screenshot.png   # read the image back
xcrun simctl openurl <device> "<appscheme>://..."         # deep-link smoke test
```

A launch with no crash is not proof the screen looks right — read the
screenshot. `simctl` has no tap injection, so navigation flows are covered by
the unit tests of §8; be explicit in the README about what was verified via
simulator versus via tests. Note that a SwiftData **schema change that isn't a
lightweight migration** (e.g. to-one → to-many) requires
`xcrun simctl uninstall` before reinstalling, or the app crashes on the stale
store.

## 7. Composition Root recipe

One `struct CompositionRoot` in the `App` target — the only file allowed to
import `Domain`, `Data`, and `Presentation` together. It owns:

- the `ModelContainer` (exposed so the App attaches `.modelContainer` — `@Query`
  and the repository must share it),
- the `SessionStore`, the `DestinationRegistry`, the tabs (each an id + icon +
  its own `AppRouter`), and a deep-link coordinator if the app has links,
- the route → view registrations (each builder receives the presenting router
  and injects a concrete flow), and one `make<Feature>Store` factory per root
  screen.

```swift
struct CompositionRoot {
    let modelContainer: ModelContainer
    let session = SessionStore()
    let registry = DestinationRegistry()
    let tabs = [AppTab(id: "Browse", systemImage: "person.3"), ...]
    private let repository: SomeRepository

    init() {
        modelContainer = try! ModelContainer(for: Item.self)
        let repository = DefaultSomeRepository.live(context: modelContainer.mainContext)
        self.repository = repository
        registry.register(ItemDetailRoute.self) { route, router in
            ItemDetailView(store: ItemDetailStore(
                item: route.item,
                someUseCase: DefaultSomeUseCase(repository: repository),
                flow: SomeFlow(router: router)
            ))
        }
        // ... one registration per reachable screen
    }
}
```

`RootView` switches on `session.isAuthenticated` between the login screen and a
`TabView` of `WireframeView`s, and forwards `onOpenURL` to the deep-link
coordinator.

If a change made in one feature must show up in another (a flag toggled in a
detail screen, an item added from a modal, a relation set by a picker), don't
wire callbacks between stores. SwiftData is the single source of truth:
mutations go intent → store → use case → repository → `ModelContext`, and any
screen keeping that data visible reads it with `@Query` (or renders the
observable `@Model` object directly), which re-renders automatically. One
source of truth, zero cross-feature coupling — no streams, Combine,
NotificationCenter, or event bus.

## 8. Testing recipe

Mirror the module graph — one test target per source target, each faking only
the layer directly below it (the Wireframe kit brings its own tests; don't
re-test it):

- **DomainTests** fake the repository protocol. The protocol is main-actor, so
  the fake is a plain `final class FakeXRepository: XRepository` with recording
  properties — no `actor`, no `Sendable` gymnastics. Test business rules:
  validation, invariants, error propagation.
- **DataTests** use the *real* repository over an **in-memory SwiftData stack**
  and a fake remote. Two hard-won rules: the helper must return the
  `ModelContainer` itself and tests must keep it alive (`mainContext` does not
  retain its container — a deallocated one leaves the context dangling and
  crashes), and the suite must be `.serialized` (concurrent `ModelContainer`
  creation for the same schema crashes intermittently). Test upsert/merge
  policy, relationship integrity on delete, the point read.
- **PresentationTests** fake every use case protocol (plain final classes with
  `errorToThrow`/recording properties) and **spy the flows**. Store tests
  assert semantic events reached the spy (`flow.selectedItems == [item]`) and
  state transitions; **flow tests** assert the resulting router intents against
  a real `AppRouter` (including child-router `dismiss` bubbling). Views own
  `#Preview`s backed by `PreviewStore`.

Because `send(_:)` kicks off `Task { }` and returns immediately, tests need to
wait for async work. One small shared helper instead of `Task.sleep` in every
test:

```swift
func waitUntil(timeout: Duration = .seconds(1), _ condition: () -> Bool) async throws {
    let deadline = ContinuousClock.now + timeout
    while !condition(), ContinuousClock.now < deadline {
        try await Task.sleep(for: .milliseconds(5))
    }
}
```

Poll on a condition that is only true *after* the async work completes, never
on something that can already be true before it starts — that race produces
flaky green tests that pass for the wrong reason. Beware vacuous tests: a
remove-test whose fake never stored the item "passes" against a no-op
implementation; pre-populate and assert the actual change.

Use `#expect(throws: SomeError.self)` for the type-only check; `#expect(throws:
someValue)` only when the error type is `Equatable`.

## 9. Verifying your own work (do this before reporting done)

```bash
swift build          # compiles the app package for macOS — fast inner-loop check
swift test           # app-package tests
(cd Wireframe && swift test)   # kit tests
```

The `import Testing` module is only available through a full Xcode toolchain,
not bare Command Line Tools — if `swift test` fails with "no such module
'Testing'", retry with `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`
rather than switching the machine's default toolchain (a system-wide change you
should not make without asking).

Then the real-app pass of §6: `xcodegen generate` → `xcodebuild` against a
simulator destination → install → launch → screenshot → read the screenshot.
Don't claim the app launches without having launched and screenshotted it in
the same session.

## 10. Documentation to produce alongside the code

- **README.md** — what the app does, project/module layout, how to build, test
  and open it.
- **DocC catalogs**, not a monolithic markdown: a `Documentation.docc` in the
  Presentation target explaining this app's architecture (layers, MVI loop,
  navigation, composition, testing) with `` ``SymbolLinks`` `` to real types,
  and the Wireframe package ships its own. Add `swift-docc-plugin` to each
  package so `swift package generate-documentation --target <T>` works, and
  regenerate after doc edits: symbol links only warn at doc-build time, so an
  unchecked catalog rots silently. Types from *other* modules are plain code
  spans, not symbol links — cross-target links don't resolve.
- **ARCHITECTURE.md** — a short pointer at the repo root (GitHub can't render
  DocC): how to read the catalogs plus an article index.

## 11. Common mistakes to avoid

- Putting navigation state (or the `@Query`-provided model data) inside a
  feature's `State`.
- Letting `Presentation` depend on `Data` "just this once" — add a use case
  instead. Same for editing the Wireframe kit to know about an app type: the
  kit stays domain-agnostic, full stop.
- Stores picking destinations (`router.send(.push(...))` from a store) — that
  is the flow's job; the store reports events.
- Doing async work directly inside `send(_:)` instead of wrapping it in
  `Task { }` — and conversely, wrapping *synchronous* local mutations
  (SwiftData writes) in needless `Task`s or swallowing their errors with
  `try?`; surface failures in `state.errorMessage`.
- Adding `@MainActor`/`Sendable` annotations everywhere out of habit — the
  targets are main-actor by default; annotations are reserved for the explicit
  boundaries (`actor` remote, `nonisolated` DTOs and routes).
- Forgetting `nonisolated` on `Route` conformers (their synthesized `Hashable`
  then crosses isolation and fails to compile) or the `@Relationship` inverse
  on self-referential/to-many relations (deletes then leave dangling
  references).
- Random seed UUIDs in the mock remote — the store is persisted; every launch
  duplicates the rows.
- In tests: not retaining the `ModelContainer`, non-`.serialized` SwiftData
  suites, and vacuous assertions (see §8).
- Using `ObservableObject`/`@Published` — this is an Observation project.
- Forgetting `#if os(iOS)` around UIKit-bridged SwiftUI modifiers, breaking the
  macOS sanity build.
