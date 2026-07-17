import Testing
import Foundation
import Domain
@testable import Presentation

@Suite("AddUserStore")
struct AddUserStoreTests {
    @Test("editing name and email updates the state")
    func editingFieldsUpdatesState() {
        let sut = AddUserStore(addUser: FakeAddUserUseCase(), router: AppRouter())

        sut.send(.nameChanged("Ada"))
        sut.send(.emailChanged("ada@example.com"))

        #expect(sut.state.name == "Ada")
        #expect(sut.state.email == "ada@example.com")
    }

    @Test("a successful save dismisses the sheet")
    func successfulSaveDismisses() async throws {
        let router = AppRouter()
        router.send(.sheet(AddUserRoute()))
        let addUser = FakeAddUserUseCase()
        addUser.userToReturn = User(name: "Ada Lovelace", email: "ada@example.com")
        let sut = AddUserStore(addUser: addUser, router: router)

        sut.send(.save)
        try await waitUntil { router.presentedSheet == nil }

        #expect(router.presentedSheet == nil)
        #expect(sut.state.errorMessage == nil)
    }

    @Test("cancel dismisses the sheet without saving")
    func cancelDismissesSheet() {
        let router = AppRouter()
        router.send(.sheet(AddUserRoute()))
        let sut = AddUserStore(addUser: FakeAddUserUseCase(), router: router)

        sut.send(.cancel)

        #expect(router.presentedSheet == nil)
    }

    @Test("a validation error from the use case is shown and the sheet stays open")
    func validationErrorKeepsSheetOpen() async throws {
        struct SampleError: Error, Sendable, LocalizedError {
            var errorDescription: String? { "invalid" }
        }
        let router = AppRouter()
        router.send(.sheet(AddUserRoute()))
        let fake = FakeAddUserUseCase()
        fake.errorToThrow = SampleError()
        let sut = AddUserStore(addUser: fake, router: router)

        sut.send(.save)
        try await waitUntil { sut.state.errorMessage != nil }

        #expect(router.presentedSheet != nil)
        #expect(sut.state.errorMessage == "invalid")
    }
}
