# Architecture

This document explains **how this codebase is built**, not what it does. The sample
app (a small user directory) exists only as a vehicle to demonstrate the architecture
end to end. Read this alongside the source — every section points at real files.

## 1. The shape: Clean Architecture + MVI

Two ideas are combined here:

- **Clean Architecture** decides how the *code is layered* and which direction
  dependencies point.
- **MVI (Model-View-Intent)** decides how *each screen* manages its state.

They operate at different scopes and compose naturally: Clean Architecture gives you
Domain / Data / Presentation modules; MVI is the internal pattern used inside every
screen that lives in the Presentation module.

## 2. Module graph and the Dependency Rule

The project is a single Swift Package (`Package.swift`) with three library targets,
plus a fourth, native Xcode target for the app itself:

```
Domain            <- no target dependencies (imports SwiftData for @Model, see §3)
Data              <- depends on Domain
Presentation      <- depends on Domain (never Data)
App               <- depends on Domain, Data, Presentation (composition root)
```

This is not just a convention described in prose — it is enforced by the compiler.
`Presentation` cannot `import Data` because it isn't listed as a dependency in
`Package.swift`; trying to do so is a build error, not a code review comment. This is
the single most important structural decision in the project: **the Dependency Rule
is a build setting, not a promise.**

```swift
// Package.swift
.target(name: "Domain"),
.target(name: "Data", dependencies: ["Domain"]),
.target(name: "Presentation", dependencies: ["Domain"]),
```

Why `Presentation` depends only on `Domain`: a screen should only know about business
concepts (`User`, `FetchUsersUseCase`) and never about *how* those concepts are
fetched or stored (`URLSession`, an actor-backed cache, a DTO). That knowledge is
Data's job, and only the composition root is allowed to introduce it.

`App` (`Sources/App`) is *not* a target in `Package.swift`: an SPM `executableTarget`
compiles fine against the iOS Simulator SDK but cannot produce an installable `.app`
bundle. Instead, [`project.yml`](project.yml) declares `App` as a real Xcode
"iOS App" target that depends on the `Domain`, `Data`, and `Presentation` products of
this package (as a local Swift Package dependency) and builds the same two files in
`Sources/App`. [XcodeGen](https://github.com/yonaskolb/XcodeGen) turns that spec into
`MVIExample.xcodeproj` on demand (`xcodegen generate`) — the project file itself
isn't committed, so it can never drift from `project.yml`. The Dependency Rule still
holds for this target: it is the only one in the whole graph, package or Xcode
project, allowed to import all three layers at once (see §7).

## 3. Domain: entities, repository contracts, use cases

`Sources/Domain` is the innermost layer. It knows nothing about SwiftUI or
networking, with one deliberate exception: the entity is a SwiftData `@Model`.

**Entity** — a `@Model` class, making one type simultaneously the schema, the
persisted row, the observable object views react to, and the navigation payload:

```swift
// Sources/Domain/Entities/User.swift
@Model
public final class User {
    public private(set) var id: UUID
    public var name: String
    public var email: String
    public var isFavorite: Bool
}
```

This trades a bit of Clean-Architecture purity (Domain imports SwiftData) for the
deletion of an entire category of code: DTO↔entity mapping for storage, a local
cache actor, and every hand-rolled change-propagation mechanism (streams,
callbacks) between features. If storage ever moved off SwiftData, `User` would
become a plain struct again and a mapping layer would return to Data.

**Repository protocol** — owned by Domain, implemented by Data. Domain defines the
contract in terms it cares about; it has no idea two data sources exist behind it:

```swift
// Sources/Domain/Repositories/UserRepository.swift
public protocol UserRepository: Sendable {
    func fetchUsers() async throws -> [User]
    func fetchUser(id: User.ID) async throws -> User
    func addUser(name: String, email: String) async throws -> User
    func setFavorite(id: User.ID, isFavorite: Bool) async throws
}
```

**Use case** — one named business operation. This is the layer Stores actually talk
to. A trivial use case is just a pass-through:

```swift
// Sources/Domain/UseCases/FetchUsersUseCase.swift
public struct DefaultFetchUsersUseCase: FetchUsersUseCase {
    private let repository: UserRepository
    public func execute() async throws -> [User] {
        try await repository.fetchUsers()
    }
}
```

But a use case is the right place to enforce invariants that must hold regardless of
caller — this is where use cases earn their keep instead of being ceremony around the
repository:

```swift
// Sources/Domain/UseCases/AddUserUseCase.swift
public func execute(name: String, email: String) async throws -> User {
    let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedName.isEmpty else { throw UserValidationError.emptyName }
    guard email.contains("@"), email.contains(".") else { throw UserValidationError.invalidEmail }
    return try await repository.addUser(name: trimmedName, email: email)
}
```

If validation lived in the Store instead, every future caller (a Shortcuts intent, a
widget, a second screen) would have to remember to re-implement it. Putting it in the
use case makes it impossible to bypass.

## 4. Data: DTOs, data sources, repository implementation

`Sources/Data` depends on Domain and implements its contracts. Nothing outside this
module knows how many data sources are involved or what a DTO looks like — `UserDTO`
and `RemoteUserDataSource` are `internal`, not `public`.

**DTO** — the wire/storage shape, decoupled from the Domain entity so an API change
doesn't ripple upward:

```swift
// Sources/Data/DTOs/UserDTO.swift
struct UserDTO: Codable, Sendable {
    let id: UUID; let name: String; let email: String; let isFavorite: Bool
    func toDomain() -> User { User(id: id, name: name, email: email, isFavorite: isFavorite) }
}
```

**Data sources** — one per origin of truth. Both are `actor`s: a real remote source
would own `URLSession` tasks and a real local source owns the cache, and actor
isolation is what makes that safe to touch from concurrent callers without manual
locks:

```swift
// Sources/Data/DataSources/RemoteUserDataSource.swift
actor MockRemoteUserDataSource: RemoteUserDataSource {
    func fetchUsers() async throws -> [UserDTO] {
        try await Task.sleep(for: .milliseconds(400)) // simulated latency
        return Self.seed
    }
}
```

**Repository implementation** — coordinates the remote source with SwiftData's
`ModelContext` (the local storage) and applies the one policy decision that belongs
at this level: a local favorite flag must never be clobbered by a stale remote
refresh.

```swift
// Sources/Data/Repositories/DefaultUserRepository.swift
public func refreshUsers() async throws {
    let dtos = try await remote.fetchUsers()
    let existingByID = Dictionary(
        uniqueKeysWithValues: try context.fetch(FetchDescriptor<User>()).map { ($0.id, $0) }
    )
    for dto in dtos {
        if let user = existingByID[dto.id] {
            user.name = dto.name   // favorite deliberately untouched
            user.email = dto.email
        } else {
            context.insert(dto.toDomain())
        }
    }
    try context.save()
}
```

Note there is no *read* method in the repository: reading is the `@Query` property
wrapper's job on the view side (§5). The repository contract covers mutations only —
refresh, add, set favorite — which is why the whole hand-rolled cache/observation
layer could be deleted. Because storage is persisted (not an in-memory cache),
favorites and locally created users survive app relaunches, and the mock remote must
return stable seed UUIDs so each launch merges into existing rows instead of
duplicating them.

## 5. Presentation: the MVI loop

Every screen is built from three pieces that always appear together, plus one
`Store` that ties them into a loop.

```
      ┌────────────────────────────────────────────┐
      │                                              │
      ▼                                              │
   ┌──────┐   send(Intent)   ┌───────┐   mutates   ┌───────┐
   │ View │ ───────────────► │ Store │ ──────────► │ State │
   └──────┘                  └───────┘             └───────┘
      ▲                                                  │
      └──────────────── @Observable re-render ───────────┘
```

- **Model** — a plain `State` struct: everything the view needs, nothing it doesn't.
- **Intent** — an `enum` of every action the view can produce (a tap, an appear
  event, a text change).
- **Store** — the only place that turns an `Intent` into a new `State`.

The contract every feature implements:

```swift
// Sources/Presentation/Core/Store.swift
@MainActor
public protocol Store<State, Intent>: AnyObject, Observable {
    associatedtype State
    associatedtype Intent
    var state: State { get }
    func send(_ intent: Intent)
}
```

`Observable` here is the Swift Observation framework (`import Observation`), not the
older `ObservableObject`/`@Published` combo. A view that reads `store.state.users`
re-renders only when `users` actually changes — there is no manual `@Published` per
field and no over-rendering when unrelated state changes.

A full feature (`Sources/Presentation/Features/UserList/UserListFeature.swift`):

```swift
public struct UserListState: Equatable, Sendable {
    public var users: [User] = []
    public var isLoading = false
    public var errorMessage: String?
}

public enum UserListIntent {
    case onAppear
    case refresh
    case selectUser(User)
    case addUserTapped
}

@Observable
@MainActor
public final class UserListStore: Store {
    public private(set) var state = UserListState()

    public func send(_ intent: UserListIntent) {
        switch intent {
        case .onAppear, .refresh: Task { await refresh() }
        case .selectUser(let user): router.push(.userDetail(user))
        case .addUserTapped: router.present(.addUser)
        }
    }

    private func refresh() async {
        state.isLoading = true
        do { try await refreshUsers.execute() }
        catch { state.errorMessage = error.localizedDescription }
        state.isLoading = false
    }
}
```

Note what is *not* in the state: the users. They reach the view through `@Query`,
which observes SwiftData directly — that is the Model half of the MVI loop:

```swift
// Sources/Presentation/Features/UserList/UserListView.swift
@Query(sort: \User.name) private var users: [User]
```

A favorite toggled on the detail screen or a user added from the sheet updates the
list automatically: SwiftData is the single source of truth and `@Query` is its
change-propagation mechanism, replacing any hand-rolled stream or cross-feature
callback. Intents remain the only way the view talks to the store.

Two rules keep this pattern honest:

1. **`send` never does async work directly.** It wraps it in `Task { }` and returns
   immediately, so the View's action always stays synchronous and non-blocking.
2. **Only the Store mutates `state`.** Views never write to `state` fields — they
   only read them and call `send`. For form fields, `Store.binding(_:send:)` builds
   a `Binding` whose setter goes through an Intent, so even two-way SwiftUI
   controls can't mutate state behind the store's back:

   ```swift
   TextField("Name", text: store.binding(\.name, send: AddUserIntent.nameChanged))
   ```

Views depend on the contract, not the class: each one stores
`any Store<State, Intent>` (the protocol has primary associated types, so no
type-erasing wrapper is needed). That is what lets every screen have a `#Preview`
backed by `PreviewStore` — a generic stub with fixed state and no-op intents —
without wiring use cases or a repository behind it.

## 6. Navigation is a side effect, not state

Where should "push to detail" or "show a sheet" live? It is tempting to add a
`route: Route?` field to every `State`, but that conflates "what does this screen
look like" with "where does the app go next" — and it forces every feature to know
about navigation types it doesn't own.

Instead, navigation lives in its own observable object, and Intent handlers call
into it directly, exactly like any other side effect (analogous to calling a use
case):

```swift
// Sources/Presentation/Core/AppRouter.swift
@Observable
public final class AppRouter {
    public enum Route: Hashable { case userDetail(User) }
    public enum Sheet: Identifiable { case addUser; ... }

    public var path: [Route] = []
    public var presentedSheet: Sheet?

    public func push(_ route: Route) { path.append(route) }
    public func present(_ sheet: Sheet) { presentedSheet = sheet }
}
```

The View binds directly to the router's arrays for `NavigationStack` (**push**) and
`.sheet(item:)` (**modal**):

```swift
// Sources/Presentation/Features/UserList/UserListView.swift
NavigationStack(path: $router.path) {
    content
        .navigationDestination(for: AppRouter.Route.self) { route in
            switch route {
            case .userDetail(let user): UserDetailView(store: makeDetailStore(user))
            }
        }
        .sheet(item: $router.presentedSheet) { sheet in
            switch sheet {
            case .addUser: AddUserView(store: makeAddUserStore())
            }
        }
}
```

`UserListView` → push → `UserDetailView` (`Sources/Presentation/Features/UserDetail`)
and `UserListView` → modal → `AddUserView`
(`Sources/Presentation/Features/AddUser`) are the two navigation paths in the sample
app. A Store never presents a `View` directly; it only ever asks the `Router` to
change a value, and the `View` layer reacts to that value. This keeps stores
UI-framework-agnostic and trivially testable (see §8).

## 7. Composition Root: where the layers actually meet

Every layer above only deals in protocols (`UserRepository`, `FetchUsersUseCase`,
...). Something has to instantiate the concrete types and wire them together —
that something is `CompositionRoot`, and it is the *only* file allowed to import
`Domain`, `Data`, and `Presentation` at once:

```swift
// Sources/App/CompositionRoot.swift
@MainActor
struct CompositionRoot {
    private let repository: UserRepository = DefaultUserRepository.live()

    func makeUserListStore(router: AppRouter) -> UserListStore {
        UserListStore(fetchUsers: DefaultFetchUsersUseCase(repository: repository), router: router)
    }
}
```

If you swapped `DefaultUserRepository` for a real networking implementation
tomorrow, this is the only file that would change. `UserListStore`, `UserListView`,
and every test in `PresentationTests` would be untouched.

## 8. Concurrency choices

- **`async/await` everywhere** a boundary crosses (use case → repository → data
  source) instead of completion handlers — errors propagate with `throws`, and
  cancellation is automatic when a `Task` is cancelled.
- **`actor` for shared mutable state** (`MockRemoteUserDataSource`) instead of locks
  or `DispatchQueue`. The compiler rejects unsynchronized access at compile time
  rather than you finding a race in production.
- **`@MainActor` instead of `Sendable` on the cross-layer contracts** (repository
  and use case protocols): SwiftData `@Model` objects are not `Sendable`, and every
  consumer — stores, use cases, the `ModelContext` — already lives on the main
  actor. Only the remote data source crosses an actor boundary, and it exchanges
  `Sendable` DTOs, never models.
- **`@MainActor` on every Store and the Router**, since they drive `@Observable`
  state that SwiftUI reads on the main thread. `send(_:)` stays synchronous; the
  `Task { await ... }` inside it is where the actual hop to background work happens.
  Local-only mutations like toggling a favorite are synchronous end to end, so
  there is no optimistic-update/rollback dance anywhere.

## 9. Testing strategy

Every layer is tested in isolation, against the layer below it faked out — never
against the real network or a real cache. All tests use the **Swift Testing**
framework (`import Testing`, `@Test`, `#expect`), not XCTest.

| Target              | Fakes what                                   | Verifies                                             |
|---------------------|-----------------------------------------------|-------------------------------------------------------|
| `DomainTests`        | `UserRepository` (`FakeUserRepository`)       | Use case business rules (e.g. validation in `AddUserUseCase`) |
| `DataTests`          | `RemoteUserDataSource` (`FakeRemoteUserDataSource`) | Repository merge/caching policy (favorite survives refresh, sorting, not-found) |
| `PresentationTests`  | Every use case protocol                       | Store state transitions and Router side effects for each Intent |

Example: `DomainTests/AddUserUseCaseTests.swift` proves the validation rule from §3
without touching any repository implementation, using `@Test(arguments:)` to run the
same assertion over several malformed emails:

```swift
@Test("rejects malformed emails", arguments: ["not-an-email", "missing-at.com", "missing-dot@example"])
func rejectsInvalidEmail(email: String) async throws {
    let sut = DefaultAddUserUseCase(repository: FakeUserRepository())
    await #expect(throws: UserValidationError.invalidEmail) {
        _ = try await sut.execute(name: "Ada Lovelace", email: email)
    }
}
```

Because Stores fire async work via `Task { }` inside a synchronous `send`, tests
can't assert on state immediately after calling `send`. `PresentationTests` share a
small `waitUntil` poll helper instead of an arbitrary `sleep`, so tests are both
fast and not flaky:

```swift
sut.send(.onAppear)
try await waitUntil { refresh.calls == 1 }
#expect(sut.state.errorMessage == nil)
```

Run everything with `swift test`. Each of the three test targets can also be run in
isolation (`swift test --filter DomainTests`) since they don't depend on each other.

## 10. Adding a new feature (recipe)

1. **Domain**: add/extend the entity if needed, declare the use case protocol +
   `Default...` implementation, extend `UserRepository` only if the operation is
   genuinely a persistence concern.
2. **Data**: implement the new repository method in `DefaultUserRepository`,
   touching `RemoteUserDataSource` as needed.
3. **Presentation**: create `<Feature>State`, `<Feature>Intent`, and a
   `@MainActor @Observable final class <Feature>Store: Store` in one
   `<Feature>Feature.swift` file, then a matching `<Feature>View.swift`.
4. **Navigation**: add a case to `AppRouter.Route` (push) or `AppRouter.Sheet`
   (modal) if the feature is reachable from another screen.
5. **App**: add a `make<Feature>Store(...)` factory method to `CompositionRoot`.
6. **Tests**: one test file per new Domain use case, one per new repository
   behavior, one per new Store — following the same fake-the-layer-below pattern
   as every existing test.

This is exactly the sequence used to build `UserList` → `UserDetail` → `AddUser` in
this repository, and it is the sequence encoded as a prompt for another agent in
[`AGENT_GUIDE.md`](AGENT_GUIDE.md).
