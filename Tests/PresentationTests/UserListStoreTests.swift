import Testing
import Foundation
import Domain
@testable import Presentation

@Suite("UserListStore")
@MainActor
struct UserListStoreTests {
    @Test("onAppear loads users from the use case")
    func onAppearLoadsUsers() async throws {
        let users = [User(name: "Ada Lovelace", email: "ada@example.com")]
        let sut = UserListStore(fetchUsers: FakeFetchUsersUseCase(usersToReturn: users), router: AppRouter())

        sut.send(.onAppear)
        try await waitUntil { !sut.state.users.isEmpty }

        #expect(sut.state.users == users)
        #expect(sut.state.errorMessage == nil)
    }

    @Test("a failed load surfaces the error message instead of the previous users")
    func failedLoadSurfacesError() async throws {
        struct SampleError: Error, Sendable, LocalizedError {
            var errorDescription: String? { "boom" }
        }
        let sut = UserListStore(fetchUsers: FakeFetchUsersUseCase(errorToThrow: SampleError()), router: AppRouter())

        sut.send(.onAppear)
        try await waitUntil { sut.state.errorMessage != nil }

        #expect(sut.state.users.isEmpty)
        #expect(sut.state.errorMessage == "boom")
    }

    @Test("selecting a user pushes a userDetail route onto the router")
    func selectUserPushesRoute() {
        let router = AppRouter()
        let sut = UserListStore(fetchUsers: FakeFetchUsersUseCase(), router: router)
        let user = User(name: "Ada Lovelace", email: "ada@example.com")

        sut.send(.selectUser(user))

        #expect(router.path == [.userDetail(user.id)])
    }

    @Test("tapping add presents the addUser sheet")
    func addUserTappedPresentsSheet() {
        let router = AppRouter()
        let sut = UserListStore(fetchUsers: FakeFetchUsersUseCase(), router: router)

        sut.send(.addUserTapped)

        #expect(router.presentedSheet?.id == AppRouter.Sheet.addUser.id)
    }

    @Test("a newly added user is inserted in sorted order")
    func userWasAddedInsertsSorted() {
        let sut = UserListStore(fetchUsers: FakeFetchUsersUseCase(), router: AppRouter())

        sut.userWasAdded(User(name: "Zoe", email: "zoe@example.com"))
        sut.userWasAdded(User(name: "Ada", email: "ada@example.com"))

        #expect(sut.state.users.map(\.name) == ["Ada", "Zoe"])
    }
}

/// Stores kick off work with `Task { ... }` from a synchronous `send`, so tests
/// poll briefly instead of assuming the update already landed by the next line.
@MainActor
func waitUntil(timeout: Duration = .seconds(1), _ condition: () -> Bool) async throws {
    let deadline = ContinuousClock.now + timeout
    while !condition(), ContinuousClock.now < deadline {
        try await Task.sleep(for: .milliseconds(5))
    }
}
