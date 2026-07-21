import Testing
import Foundation
import Domain
@testable import Presentation

@Suite("SelectRelatedUsersStore")
struct SelectRelatedUsersStoreTests {
    private func makeSut(
        target: User,
        add: FakeAddRelatedUserUseCase = FakeAddRelatedUserUseCase(),
        remove: FakeRemoveRelatedUserUseCase = FakeRemoveRelatedUserUseCase(),
        flow: SelectRelatedFlowSpy = SelectRelatedFlowSpy()
    ) -> SelectRelatedUsersStore {
        SelectRelatedUsersStore(target: target, addRelated: add, removeRelated: remove, flow: flow)
    }

    @Test("toggling a non-related user adds it")
    func toggleAdds() {
        let target = User(name: "Ada Lovelace", email: "ada@example.com")
        let other = User(name: "Alan Turing", email: "alan@example.com")
        let add = FakeAddRelatedUserUseCase()
        let sut = makeSut(target: target, add: add)

        sut.send(.toggle(other))

        #expect(add.calls.count == 1)
        #expect(target.related.map(\.id) == [other.id])
    }

    @Test("toggling an already-related user removes it")
    func toggleRemoves() {
        let target = User(name: "Ada Lovelace", email: "ada@example.com")
        let other = User(name: "Alan Turing", email: "alan@example.com")
        target.related = [other]
        let remove = FakeRemoveRelatedUserUseCase()
        let sut = makeSut(target: target, remove: remove)

        sut.send(.toggle(other))

        #expect(remove.calls.count == 1)
        #expect(target.related.isEmpty)
    }

    @Test("a failed toggle surfaces the error message")
    func failedToggleSurfacesError() {
        struct SampleError: Error, Sendable, LocalizedError {
            var errorDescription: String? { "boom" }
        }
        let target = User(name: "Ada Lovelace", email: "ada@example.com")
        let other = User(name: "Alan Turing", email: "alan@example.com")
        let add = FakeAddRelatedUserUseCase()
        add.errorToThrow = SampleError()
        let sut = makeSut(target: target, add: add)

        sut.send(.toggle(other))

        #expect(sut.state.errorMessage == "boom")
    }

    @Test("done is forwarded to the flow")
    func doneForwardedToFlow() {
        let flow = SelectRelatedFlowSpy()
        let sut = makeSut(target: User(name: "Ada", email: "ada@example.com"), flow: flow)

        sut.send(.doneTapped)

        #expect(flow.finishCount == 1)
    }
}
