import Testing
import Domain
@testable import Presentation

@Suite("UserDetailStore")
struct UserDetailStoreTests {
    private func makeSut(
        user: User,
        toggle: FakeToggleFavoriteUseCase = FakeToggleFavoriteUseCase(),
        flow: UserDetailFlowSpy = UserDetailFlowSpy()
    ) -> UserDetailStore {
        UserDetailStore(user: user, toggleFavorite: toggle, flow: flow)
    }

    @Test("toggling favorite forwards the flipped value to the use case")
    func toggleFavoriteForwardsFlippedValue() {
        let user = User(name: "Alan Turing", email: "alan@example.com", isFavorite: false)
        let toggle = FakeToggleFavoriteUseCase()
        let sut = makeSut(user: user, toggle: toggle)

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
        let sut = makeSut(user: user, toggle: toggle)

        sut.send(.toggleFavorite)

        #expect(user.isFavorite == false)
        #expect(sut.state.errorMessage != nil)
    }

    @Test("managing related users asks the flow to open the modal")
    func manageRelatedAsksFlow() {
        let user = User(name: "Alan Turing", email: "alan@example.com")
        let flow = UserDetailFlowSpy()
        let sut = makeSut(user: user, flow: flow)

        sut.send(.manageRelatedTapped)

        #expect(flow.manageRequests.map(\.id) == [user.id])
    }
}
