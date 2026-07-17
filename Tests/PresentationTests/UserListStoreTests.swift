import Testing
import Foundation
import Domain
@testable import Presentation

@Suite("UserListStore")
struct UserListStoreTests {
    @Test("onAppear triggers a remote refresh")
    func onAppearTriggersRefresh() async throws {
        let refresh = FakeRefreshUsersUseCase()
        let sut = UserListStore(refreshUsers: refresh, router: AppRouter())

        sut.send(.onAppear)
        try await waitUntil { refresh.calls == 1 }

        #expect(refresh.calls == 1)
        #expect(sut.state.errorMessage == nil)
    }

    @Test("a failed refresh surfaces the error message")
    func failedRefreshSurfacesError() async throws {
        struct SampleError: Error, Sendable, LocalizedError {
            var errorDescription: String? { "boom" }
        }
        let refresh = FakeRefreshUsersUseCase()
        refresh.errorToThrow = SampleError()
        let sut = UserListStore(refreshUsers: refresh, router: AppRouter())

        sut.send(.refresh)
        try await waitUntil { sut.state.errorMessage != nil }

        #expect(sut.state.errorMessage == "boom")
        #expect(sut.state.isLoading == false)
    }

    @Test("selecting a user pushes a userDetail route onto the router")
    func selectUserPushesRoute() {
        let router = AppRouter()
        let sut = UserListStore(refreshUsers: FakeRefreshUsersUseCase(), router: router)
        let user = User(name: "Ada Lovelace", email: "ada@example.com")

        sut.send(.selectUser(user))

        #expect(router.routes == [AnyHashable(UserDetailRoute(user: user))])
        #expect(router.path.count == 1)
    }

    @Test("tapping add presents the addUser sheet")
    func addUserTappedPresentsSheet() {
        let router = AppRouter()
        let sut = UserListStore(refreshUsers: FakeRefreshUsersUseCase(), router: router)

        sut.send(.addUserTapped)

        #expect(router.presentedSheet?.id == Sheet.addUser.id)
    }
}

/// Stores kick off work with `Task { ... }` from a synchronous `send`, so tests
/// poll briefly instead of assuming the update already landed by the next line.
func waitUntil(timeout: Duration = .seconds(1), _ condition: () -> Bool) async throws {
    let deadline = ContinuousClock.now + timeout
    while !condition(), ContinuousClock.now < deadline {
        try await Task.sleep(for: .milliseconds(5))
    }
}
