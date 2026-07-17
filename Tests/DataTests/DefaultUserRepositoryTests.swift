import Testing
import Foundation
import Domain
@testable import Data

@Suite("DefaultUserRepository")
struct DefaultUserRepositoryTests {
    @Test("fetchUsers caches remote results and returns them sorted by name")
    func fetchUsersSortsByName() async throws {
        let remote = FakeRemoteUserDataSource()
        await remote.set(usersToReturn: [
            UserDTO(id: UUID(), name: "Grace Hopper", email: "grace@example.com", isFavorite: false),
            UserDTO(id: UUID(), name: "Ada Lovelace", email: "ada@example.com", isFavorite: false)
        ])
        let sut = DefaultUserRepository(remote: remote, local: LocalUserStore())

        let users = try await sut.fetchUsers()

        #expect(users.map(\.name) == ["Ada Lovelace", "Grace Hopper"])
    }

    @Test("a local favorite flag survives a subsequent remote refresh")
    func favoriteSurvivesRefresh() async throws {
        let id = UUID()
        let remote = FakeRemoteUserDataSource()
        await remote.set(usersToReturn: [UserDTO(id: id, name: "Ada Lovelace", email: "ada@example.com", isFavorite: false)])
        let sut = DefaultUserRepository(remote: remote, local: LocalUserStore())

        _ = try await sut.fetchUsers()
        try await sut.setFavorite(id: id, isFavorite: true)
        let usersAfterRefresh = try await sut.fetchUsers()

        #expect(usersAfterRefresh.first(where: { $0.id == id })?.isFavorite == true)
    }

    @Test("observeUsers emits the current snapshot, then again when a favorite changes")
    func observeEmitsOnFavoriteChange() async throws {
        let id = UUID()
        let remote = FakeRemoteUserDataSource()
        await remote.set(usersToReturn: [UserDTO(id: id, name: "Ada Lovelace", email: "ada@example.com", isFavorite: false)])
        let sut = DefaultUserRepository(remote: remote, local: LocalUserStore())
        _ = try await sut.fetchUsers()

        var iterator = await sut.observeUsers().makeAsyncIterator()
        let initial = await iterator.next()
        try await sut.setFavorite(id: id, isFavorite: true)
        let afterToggle = await iterator.next()

        #expect(initial?.first?.isFavorite == false)
        #expect(afterToggle?.first?.isFavorite == true)
    }

    @Test("observeUsers emits when a new user is added")
    func observeEmitsOnAddUser() async throws {
        let sut = DefaultUserRepository(remote: FakeRemoteUserDataSource(), local: LocalUserStore())

        var iterator = await sut.observeUsers().makeAsyncIterator()
        let initial = await iterator.next()
        _ = try await sut.addUser(name: "Katherine Johnson", email: "katherine@example.com")
        let afterAdd = await iterator.next()

        #expect(initial?.isEmpty == true)
        #expect(afterAdd?.map(\.name) == ["Katherine Johnson"])
    }

    @Test("fetchUser throws notFound for an id that was never cached")
    func fetchUserThrowsWhenMissing() async throws {
        let sut = DefaultUserRepository(remote: FakeRemoteUserDataSource(), local: LocalUserStore())

        await #expect(throws: UserRepositoryError.self) {
            _ = try await sut.fetchUser(id: UUID())
        }
    }

    @Test("addUser forwards to the remote source and caches the created user")
    func addUserCachesResult() async throws {
        let remote = FakeRemoteUserDataSource()
        let sut = DefaultUserRepository(remote: remote, local: LocalUserStore())

        let created = try await sut.addUser(name: "Katherine Johnson", email: "katherine@example.com")
        let fetched = try await sut.fetchUser(id: created.id)

        #expect(fetched.name == "Katherine Johnson")
        let calls = await remote.createUserCalls
        #expect(calls.count == 1)
    }
}
