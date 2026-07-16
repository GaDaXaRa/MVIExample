import Testing
import Foundation
import Domain
@testable import Presentation

@Suite("AddUserStore")
@MainActor
struct AddUserStoreTests {
    @Test("editing name and email updates the state")
    func editingFieldsUpdatesState() {
        let sut = AddUserStore(addUser: FakeAddUserUseCase(), router: AppRouter(), onSaved: { _ in })

        sut.send(.nameChanged("Ada"))
        sut.send(.emailChanged("ada@example.com"))

        #expect(sut.state.name == "Ada")
        #expect(sut.state.email == "ada@example.com")
    }

    @Test("a successful save notifies the caller and dismisses the sheet")
    func successfulSaveDismisses() async throws {
        let router = AppRouter()
        router.present(.addUser)
        let savedUser = User(name: "Ada Lovelace", email: "ada@example.com")
        var reportedUser: User?
        let sut = AddUserStore(
            addUser: FakeAddUserUseCase(userToReturn: savedUser),
            router: router,
            onSaved: { reportedUser = $0 }
        )

        sut.send(.save)
        try await waitUntil { router.presentedSheet == nil }

        #expect(reportedUser == savedUser)
    }

    @Test("cancel dismisses the sheet without saving")
    func cancelDismissesSheet() {
        let router = AppRouter()
        router.present(.addUser)
        let sut = AddUserStore(addUser: FakeAddUserUseCase(), router: router, onSaved: { _ in })

        sut.send(.cancel)

        #expect(router.presentedSheet == nil)
    }

    @Test("a validation error from the use case is shown and the sheet stays open")
    func validationErrorKeepsSheetOpen() async throws {
        struct SampleError: Error, Sendable, LocalizedError {
            var errorDescription: String? { "invalid" }
        }
        let router = AppRouter()
        router.present(.addUser)
        var fake = FakeAddUserUseCase()
        fake.errorToThrow = SampleError()
        let sut = AddUserStore(addUser: fake, router: router, onSaved: { _ in })

        sut.send(.save)
        try await waitUntil { sut.state.errorMessage != nil }

        #expect(router.presentedSheet != nil)
        #expect(sut.state.errorMessage == "invalid")
    }
}
