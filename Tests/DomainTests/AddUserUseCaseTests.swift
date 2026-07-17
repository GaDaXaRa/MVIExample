import Testing
@testable import Domain

@Suite("AddUserUseCase")
@MainActor
struct AddUserUseCaseTests {
    @Test("rejects an empty name")
    func rejectsEmptyName() async throws {
        let sut = DefaultAddUserUseCase(repository: FakeUserRepository())

        await #expect(throws: UserValidationError.emptyName) {
            _ = try await sut.execute(name: "   ", email: "ada@example.com")
        }
    }

    @Test(
        "rejects malformed emails",
        arguments: ["not-an-email", "missing-at.com", "missing-dot@example"]
    )
    func rejectsInvalidEmail(email: String) async throws {
        let sut = DefaultAddUserUseCase(repository: FakeUserRepository())

        await #expect(throws: UserValidationError.invalidEmail) {
            _ = try await sut.execute(name: "Ada Lovelace", email: email)
        }
    }

    @Test("trims the name and forwards a valid user to the repository")
    func forwardsValidUser() async throws {
        let repository = FakeUserRepository()
        let sut = DefaultAddUserUseCase(repository: repository)

        let user = try await sut.execute(name: "  Ada Lovelace  ", email: "ada@example.com")

        #expect(user.name == "Ada Lovelace")
        #expect(repository.addUserCalls.count == 1)
        #expect(repository.addUserCalls.first?.name == "Ada Lovelace")
    }
}
