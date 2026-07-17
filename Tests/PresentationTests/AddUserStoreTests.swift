import Testing
import Foundation
import Domain
@testable import Presentation

@Suite("AddUserStore")
struct AddUserStoreTests {
    @Test("editing name and email updates the state")
    func editingFieldsUpdatesState() {
        let sut = AddUserStore(addUser: FakeAddUserUseCase(), flow: AddUserFlowSpy())

        sut.send(.nameChanged("Ada"))
        sut.send(.emailChanged("ada@example.com"))

        #expect(sut.state.name == "Ada")
        #expect(sut.state.email == "ada@example.com")
    }

    @Test("a successful save reports didFinish to the flow")
    func successfulSaveFinishes() async throws {
        let flow = AddUserFlowSpy()
        let addUser = FakeAddUserUseCase()
        addUser.userToReturn = User(name: "Ada Lovelace", email: "ada@example.com")
        let sut = AddUserStore(addUser: addUser, flow: flow)

        sut.send(.save)
        try await waitUntil { flow.finishCount == 1 }

        #expect(flow.finishCount == 1)
        #expect(sut.state.errorMessage == nil)
    }

    @Test("cancel reports didCancel without saving")
    func cancelReportsToFlow() {
        let flow = AddUserFlowSpy()
        let sut = AddUserStore(addUser: FakeAddUserUseCase(), flow: flow)

        sut.send(.cancel)

        #expect(flow.cancelCount == 1)
        #expect(flow.finishCount == 0)
    }

    @Test("a validation error is shown and the flow is not notified")
    func validationErrorDoesNotFinish() async throws {
        struct SampleError: Error, Sendable, LocalizedError {
            var errorDescription: String? { "invalid" }
        }
        let flow = AddUserFlowSpy()
        let fake = FakeAddUserUseCase()
        fake.errorToThrow = SampleError()
        let sut = AddUserStore(addUser: fake, flow: flow)

        sut.send(.save)
        try await waitUntil { sut.state.errorMessage != nil }

        #expect(flow.finishCount == 0)
        #expect(sut.state.errorMessage == "invalid")
    }
}
