# Clean Architecture and the Dependency Rule

How the code is layered, and why the compiler — not a convention — enforces it.

## Overview

The app-specific code is one Swift Package with three library targets, plus a
native Xcode App target; the domain-agnostic core is a **separate package in its
own repository**, `Wireframe`, consumed as a versioned dependency:

```
Wireframe (pkg)   ← MVI + navigation kit, knows no app entities
Domain            ← no target dependencies (imports SwiftData for @Model)
Data              ← depends on Domain
Presentation      ← depends on Domain + Wireframe (never Data)
App               ← depends on all of the above (composition root)
```

This is not just prose — it is enforced by the compiler. `Presentation` cannot
`import Data` because it isn't listed as a dependency in `Package.swift`; trying
is a build error. **The Dependency Rule is a build setting, not a promise.**

```swift
// Package.swift
.target(name: "Domain"),
.target(name: "Data", dependencies: ["Domain"]),
.target(name: "Presentation", dependencies: ["Domain", .product(name: "Wireframe", package: "swift-wireframe")]),
```

`Wireframe` being a *separate package* (not just another target) is deliberate:
a target could still be made to depend on an app target, but a separate package
has a one-way dependency by construction — the kit can never reach into `Domain`
or a feature. It only depends on SwiftUI/Observation, so it drops into any app,
which is why it now lives in its own repository and is versioned independently.

`App` (`Sources/App`) is *not* a package target: an SPM `executableTarget` cannot
produce an installable `.app` bundle. Instead `project.yml` declares it as a real
Xcode "iOS App" target that depends on the three products, and
[XcodeGen](https://github.com/yonaskolb/XcodeGen) turns that spec into
`MVIExample.xcodeproj` on demand — the project file isn't committed, so it can
never drift from `project.yml`.

## Domain: entities, contracts, use cases

`Domain` is the innermost layer. It knows nothing about SwiftUI or networking,
with one deliberate exception: the entity is a SwiftData `@Model`.

```swift
// Sources/Domain/Entities/User.swift
@Model
public final class User {
    public private(set) var id: UUID
    public var name: String
    public var email: String
    public var isFavorite: Bool
    public var related: User?   // self-referential to-one relationship
}
```

Making `User` a `@Model` trades a little Clean-Architecture purity (Domain imports
SwiftData) for the deletion of an entire category of code: DTO↔entity mapping for
storage, a local cache, and every hand-rolled change-propagation mechanism between
features. Because the model is observable, a favorite toggled on one screen, or a
relation set from a modal, updates every other screen showing that user with no
callbacks.

The repository protocol is owned by Domain and implemented by Data. It is
**mutations plus a single point read**: lists are observed with `@Query` on the
view side (see <doc:TheMVILoop>), so the only read here resolves one entity by id
(a deep link carries an id, not an object).

```swift
// Sources/Domain/Repositories/UserRepository.swift
public protocol UserRepository {
    func refreshUsers() async throws
    func addUser(name: String, email: String) async throws -> User
    func setFavorite(_ user: User, isFavorite: Bool) throws
    func addRelated(_ related: User, to user: User) throws
    func removeRelated(_ related: User, from user: User) throws
    func remove(_ user: User) throws
    func user(id: UUID) throws -> User?   // the one read, for deep links
}
```

A **use case** is one named business operation, and the right place to enforce
invariants that must hold regardless of caller. `AddUserUseCase` validates before
saving; `AddRelatedUserUseCase` rejects a self-relation and de-duplicates. If those
rules lived in a store, every future caller (a Shortcuts intent, a widget, a second
screen) would have to re-implement them:

```swift
// Sources/Domain/UseCases/RelatedUserUseCases.swift
public func execute(_ related: User, to user: User) throws {
    guard related.id != user.id else { throw UserRelationError.selfRelation }
    guard !user.related.contains(where: { $0.id == related.id }) else { return }
    try repository.addRelated(related, to: user)
}
```

## Data: DTOs, data sources, repository

`Data` implements Domain's contracts. Nothing outside it knows how many data
sources exist or what a DTO looks like — `UserDTO` and `RemoteUserDataSource` are
`internal`. The remote source is an `actor` (a real one would own `URLSession`
tasks); local storage is SwiftData's `ModelContext`.

The repository applies the one policy that belongs at this level — a local
favorite must never be clobbered by a stale remote refresh:

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

Because storage is persisted, favorites and locally created users survive app
relaunches, and the mock remote returns stable seed UUIDs so each launch merges
into existing rows instead of duplicating them.

## Topics

- <doc:TheMVILoop>
- <doc:Composition>
