import Testing
import Foundation
import Domain
@testable import Presentation

@Suite("UserListStore")
@MainActor
struct UserListStoreTests {
    @Test("onAppear subscribes to the stream and renders whatever it emits")
    func onAppearRendersStreamEmissions() async throws {
        let users = [User(name: "Ada Lovelace", email: "ada@example.com")]
        let observe = FakeObserveUsersUseCase()
        let sut = UserListStore(observeUsers: observe, fetchUsers: FakeFetchUsersUseCase(), router: AppRouter())

        sut.send(.onAppear)
        observe.emit(users)
        try await waitUntil { !sut.state.users.isEmpty }

        #expect(sut.state.users == users)
        #expect(sut.state.errorMessage == nil)
    }

    @Test("a later emission (e.g. a favorite toggled in the detail screen) replaces the list")
    func laterEmissionReplacesList() async throws {
        var user = User(name: "Ada Lovelace", email: "ada@example.com")
        let observe = FakeObserveUsersUseCase()
        let sut = UserListStore(observeUsers: observe, fetchUsers: FakeFetchUsersUseCase(), router: AppRouter())

        sut.send(.onAppear)
        observe.emit([user])
        try await waitUntil { !sut.state.users.isEmpty }

        user.isFavorite = true
        observe.emit([user])
        try await waitUntil { sut.state.users.first?.isFavorite == true }

        #expect(sut.state.users == [user])
    }

    @Test("a failed refresh surfaces the error message")
    func failedRefreshSurfacesError() async throws {
        struct SampleError: Error, Sendable, LocalizedError {
            var errorDescription: String? { "boom" }
        }
        let sut = UserListStore(
            observeUsers: FakeObserveUsersUseCase(),
            fetchUsers: FakeFetchUsersUseCase(errorToThrow: SampleError()),
            router: AppRouter()
        )

        sut.send(.onAppear)
        try await waitUntil { sut.state.errorMessage != nil }

        #expect(sut.state.users.isEmpty)
        #expect(sut.state.errorMessage == "boom")
    }

    @Test("selecting a user pushes a userDetail route onto the router")
    func selectUserPushesRoute() {
        let router = AppRouter()
        let sut = UserListStore(observeUsers: FakeObserveUsersUseCase(), fetchUsers: FakeFetchUsersUseCase(), router: router)
        let user = User(name: "Ada Lovelace", email: "ada@example.com")

        sut.send(.selectUser(user))

        #expect(router.path == [.userDetail(user.id)])
    }

    @Test("tapping add presents the addUser sheet")
    func addUserTappedPresentsSheet() {
        let router = AppRouter()
        let sut = UserListStore(observeUsers: FakeObserveUsersUseCase(), fetchUsers: FakeFetchUsersUseCase(), router: router)

        sut.send(.addUserTapped)

        #expect(router.presentedSheet?.id == AppRouter.Sheet.addUser.id)
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
