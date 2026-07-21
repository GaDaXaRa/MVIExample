import Testing
import Foundation
import SwiftData
import Domain
@testable import Data

// `.serialized` because each test builds its own ModelContainer and SwiftData
// intermittently crashes (SIGSEGV) when containers for the same schema are
// created concurrently. Serializing only this suite keeps the rest parallel.
@Suite("DefaultUserRepository", .serialized)
struct DefaultUserRepositoryTests {
    /// Fresh, in-memory SwiftData stack per test: same schema as production,
    /// no disk state shared between tests. Tests must keep the returned
    /// container alive — `mainContext` does not retain it, and a deallocated
    /// container leaves the context with a dangling weak reference (crash).
    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: User.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    @Test("refreshUsers upserts the remote users into the store")
    func refreshUpsertsRemoteUsers() async throws {
        let container = try makeContainer()
        let context = container.mainContext
        let remote = FakeRemoteUserDataSource()
        await remote.set(usersToReturn: [
            UserDTO(id: UUID(), name: "Grace Hopper", email: "grace@example.com", isFavorite: false),
            UserDTO(id: UUID(), name: "Ada Lovelace", email: "ada@example.com", isFavorite: false)
        ])
        let sut = DefaultUserRepository(context: context, remote: remote)

        try await sut.refreshUsers()

        let users = try context.fetch(FetchDescriptor<User>(sortBy: [SortDescriptor(\.name)]))
        #expect(users.map(\.name) == ["Ada Lovelace", "Grace Hopper"])
    }

    @Test("a local favorite flag survives a subsequent remote refresh")
    func favoriteSurvivesRefresh() async throws {
        let container = try makeContainer()
        let context = container.mainContext
        let id = UUID()
        let remote = FakeRemoteUserDataSource()
        await remote.set(usersToReturn: [UserDTO(id: id, name: "Ada Lovelace", email: "ada@example.com", isFavorite: false)])
        let sut = DefaultUserRepository(context: context, remote: remote)

        try await sut.refreshUsers()
        let user = try #require(try context.fetch(FetchDescriptor<User>()).first)
        try sut.setFavorite(user, isFavorite: true)
        try await sut.refreshUsers()

        #expect(user.isFavorite == true)
        #expect(try context.fetchCount(FetchDescriptor<User>()) == 1)
    }

    @Test("addUser forwards to the remote source and stores the created user")
    func addUserStoresResult() async throws {
        let container = try makeContainer()
        let context = container.mainContext
        let remote = FakeRemoteUserDataSource()
        let sut = DefaultUserRepository(context: context, remote: remote)

        let created = try await sut.addUser(name: "Katherine Johnson", email: "katherine@example.com")

        let stored = try #require(try context.fetch(FetchDescriptor<User>()).first)
        #expect(stored.id == created.id)
        #expect(stored.name == "Katherine Johnson")
        let calls = await remote.createUserCalls
        #expect(calls.count == 1)
    }

    @Test("addRelated and removeRelated persist the many-to-many relation")
    func relationsPersist() async throws {
        let container = try makeContainer()
        let context = container.mainContext
        let ada = User(name: "Ada Lovelace", email: "ada@example.com")
        let alan = User(name: "Alan Turing", email: "alan@example.com")
        let grace = User(name: "Grace Hopper", email: "grace@example.com")
        for user in [ada, alan, grace] { context.insert(user) }
        try context.save()
        let sut = DefaultUserRepository(context: context, remote: FakeRemoteUserDataSource())

        try sut.addRelated(alan, to: ada)
        try sut.addRelated(grace, to: ada)
        #expect(Set(ada.related.map(\.id)) == [alan.id, grace.id])

        try sut.removeRelated(alan, from: ada)
        #expect(ada.related.map(\.id) == [grace.id])
    }

    @Test("user(id:) resolves a stored user and returns nil for an unknown id")
    func userByIdResolves() async throws {
        let container = try makeContainer()
        let context = container.mainContext
        let ada = User(name: "Ada Lovelace", email: "ada@example.com")
        context.insert(ada)
        try context.save()
        let sut = DefaultUserRepository(context: context, remote: FakeRemoteUserDataSource())

        #expect(try sut.user(id: ada.id)?.name == "Ada Lovelace")
        #expect(try sut.user(id: UUID()) == nil)
    }

    @Test("removing a user deletes it and nullifies anyone who had it as related")
    func removeNullifiesReferrers() async throws {
        let container = try makeContainer()
        let context = container.mainContext
        let ada = User(name: "Ada Lovelace", email: "ada@example.com")
        let alan = User(name: "Alan Turing", email: "alan@example.com")
        context.insert(ada)
        context.insert(alan)
        ada.related = [alan]
        try context.save()
        let sut = DefaultUserRepository(context: context, remote: FakeRemoteUserDataSource())

        try sut.remove(alan)

        #expect(ada.related.isEmpty)
        #expect(try context.fetchCount(FetchDescriptor<User>()) == 1)
    }

    @Test("setFavorite persists the new value")
    func setFavoritePersists() async throws {
        let container = try makeContainer()
        let context = container.mainContext
        let user = User(name: "Ada Lovelace", email: "ada@example.com", isFavorite: false)
        context.insert(user)
        try context.save()
        let sut = DefaultUserRepository(context: context, remote: FakeRemoteUserDataSource())

        try sut.setFavorite(user, isFavorite: true)

        let persisted = try #require(try context.fetch(FetchDescriptor<User>()).first)
        #expect(persisted.isFavorite == true)
    }
}
