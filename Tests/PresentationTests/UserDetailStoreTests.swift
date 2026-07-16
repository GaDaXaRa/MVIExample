import Testing
import Domain
@testable import Presentation

@Suite("UserDetailStore")
@MainActor
struct UserDetailStoreTests {
    @Test("onAppear loads the user detail")
    func onAppearLoadsDetail() async throws {
        let user = User(name: "Alan Turing", email: "alan@example.com")
        let sut = UserDetailStore(
            userID: user.id,
            fetchUserDetail: FakeFetchUserDetailUseCase(userToReturn: user),
            toggleFavorite: FakeToggleFavoriteUseCase()
        )

        sut.send(.onAppear)
        try await waitUntil { sut.state.user != nil }

        #expect(sut.state.user == user)
    }

    @Test("toggling favorite updates the state optimistically and calls the use case")
    func toggleFavoriteUpdatesOptimistically() async throws {
        let user = User(name: "Alan Turing", email: "alan@example.com", isFavorite: false)
        let toggle = FakeToggleFavoriteUseCase()
        let sut = UserDetailStore(
            userID: user.id,
            fetchUserDetail: FakeFetchUserDetailUseCase(userToReturn: user),
            toggleFavorite: toggle
        )
        sut.send(.onAppear)
        try await waitUntil { sut.state.user != nil }

        sut.send(.toggleFavorite)
        try await waitUntil { toggle.calls.count == 1 }

        #expect(sut.state.user?.isFavorite == true)
        #expect(toggle.calls.first?.isFavorite == true)
    }

    @Test("a failed toggle rolls the optimistic update back")
    func toggleFavoriteRollsBackOnFailure() async throws {
        struct SampleError: Error, Sendable {}
        let user = User(name: "Alan Turing", email: "alan@example.com", isFavorite: false)
        let toggle = FakeToggleFavoriteUseCase()
        toggle.errorToThrow = SampleError()
        let sut = UserDetailStore(
            userID: user.id,
            fetchUserDetail: FakeFetchUserDetailUseCase(userToReturn: user),
            toggleFavorite: toggle
        )
        sut.send(.onAppear)
        try await waitUntil { sut.state.user != nil }

        sut.send(.toggleFavorite)
        try await waitUntil { sut.state.errorMessage != nil }

        #expect(sut.state.user?.isFavorite == false)
    }
}
