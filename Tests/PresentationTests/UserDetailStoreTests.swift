import Testing
import Domain
@testable import Presentation

@Suite("UserDetailStore")
struct UserDetailStoreTests {
    private func makeSut(
        user: User,
        toggle: FakeToggleFavoriteUseCase = FakeToggleFavoriteUseCase(),
        setRelated: FakeSetRelatedUserUseCase = FakeSetRelatedUserUseCase(),
        flow: UserDetailFlowSpy = UserDetailFlowSpy()
    ) -> UserDetailStore {
        UserDetailStore(user: user, toggleFavorite: toggle, setRelated: setRelated, flow: flow)
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

    @Test("adding a related user asks the flow for the picker")
    func addRelatedAsksFlowForPicker() {
        let user = User(name: "Alan Turing", email: "alan@example.com")
        let flow = UserDetailFlowSpy()
        let sut = makeSut(user: user, flow: flow)

        sut.send(.addRelatedTapped)

        #expect(flow.pickerRequests.map(\.id) == [user.id])
    }

    @Test("tapping the related user reports it to the flow; without one, nothing happens")
    func relatedTappedReportsToFlow() {
        let user = User(name: "Alan Turing", email: "alan@example.com")
        let flow = UserDetailFlowSpy()
        let sut = makeSut(user: user, flow: flow)

        sut.send(.relatedTapped)
        #expect(flow.selectedRelated.isEmpty)

        let related = User(name: "Ada Lovelace", email: "ada@example.com")
        user.related = related
        sut.send(.relatedTapped)
        #expect(flow.selectedRelated.map(\.id) == [related.id])
    }

    @Test("removing the related user clears it through the use case")
    func removeRelatedClearsRelation() {
        let user = User(name: "Alan Turing", email: "alan@example.com")
        user.related = User(name: "Ada Lovelace", email: "ada@example.com")
        let setRelated = FakeSetRelatedUserUseCase()
        let sut = makeSut(user: user, setRelated: setRelated)

        sut.send(.removeRelatedTapped)

        #expect(user.related == nil)
        #expect(setRelated.calls.count == 1)
        #expect(setRelated.calls.first?.related == nil)
    }
}
