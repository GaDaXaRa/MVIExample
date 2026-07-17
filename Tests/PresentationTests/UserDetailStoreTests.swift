import Testing
import Domain
@testable import Presentation

@Suite("UserDetailStore")
@MainActor
struct UserDetailStoreTests {
    @Test("toggling favorite forwards the flipped value to the use case")
    func toggleFavoriteForwardsFlippedValue() {
        let user = User(name: "Alan Turing", email: "alan@example.com", isFavorite: false)
        let toggle = FakeToggleFavoriteUseCase()
        let sut = UserDetailStore(user: user, toggleFavorite: toggle)

        sut.send(.toggleFavorite)

        #expect(user.isFavorite == true)
        #expect(toggle.calls.count == 1)
        #expect(toggle.calls.first?.isFavorite == true)
    }

    @Test("a failed toggle surfaces the error and leaves the user unchanged")
    func failedToggleSurfacesError() {
        struct SampleError: Error, Sendable {}
        let user = User(name: "Alan Turing", email: "alan@example.com", isFavorite: false)
        let toggle = FakeToggleFavoriteUseCase()
        toggle.errorToThrow = SampleError()
        let sut = UserDetailStore(user: user, toggleFavorite: toggle)

        sut.send(.toggleFavorite)

        #expect(user.isFavorite == false)
        #expect(sut.state.errorMessage != nil)
    }
}
