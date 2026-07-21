import Testing
import Foundation
@testable import Domain

@Suite("RefreshUsersUseCase")
struct RefreshUsersUseCaseTests {
    @Test("forwards the refresh to the repository")
    func forwardsRefresh() async throws {
        let repository = FakeUserRepository()
        let sut = DefaultRefreshUsersUseCase(repository: repository)

        try await sut.execute()

        #expect(repository.refreshCalls == 1)
    }
}

@Suite("AddRelatedUserUseCase")
struct AddRelatedUserUseCaseTests {
    @Test("adds the related user to the target")
    func addsRelation() throws {
        let repository = FakeUserRepository()
        let sut = DefaultAddRelatedUserUseCase(repository: repository)
        let user = User(name: "Ada Lovelace", email: "ada@example.com")
        let related = User(name: "Alan Turing", email: "alan@example.com")

        try sut.execute(related, to: user)

        #expect(user.related.map(\.id) == [related.id])
        #expect(repository.relationUpdates.count == 1)
    }

    @Test("adding an already-related user is a no-op")
    func addIsIdempotent() throws {
        let repository = FakeUserRepository()
        let sut = DefaultAddRelatedUserUseCase(repository: repository)
        let user = User(name: "Ada Lovelace", email: "ada@example.com")
        let related = User(name: "Alan Turing", email: "alan@example.com")
        user.related = [related]

        try sut.execute(related, to: user)

        #expect(user.related.count == 1)
        #expect(repository.relationUpdates.isEmpty)
    }

    @Test("rejects relating a user to themselves")
    func rejectsSelfRelation() throws {
        let repository = FakeUserRepository()
        let sut = DefaultAddRelatedUserUseCase(repository: repository)
        let user = User(name: "Ada Lovelace", email: "ada@example.com")

        #expect(throws: UserRelationError.selfRelation) {
            try sut.execute(user, to: user)
        }
        #expect(repository.relationUpdates.isEmpty)
    }
}

@Suite("RemoveRelatedUserUseCase")
struct RemoveRelatedUserUseCaseTests {
    @Test("removes the related user from the target")
    func removesRelation() throws {
        let repository = FakeUserRepository()
        let sut = DefaultRemoveRelatedUserUseCase(repository: repository)
        let user = User(name: "Ada Lovelace", email: "ada@example.com")
        let related = User(name: "Alan Turing", email: "alan@example.com")
        user.related = [related]

        try sut.execute(related, from: user)

        #expect(user.related.isEmpty)
    }
}

@Suite("ToggleFavoriteUseCase")
struct ToggleFavoriteUseCaseTests {
    @Test("forwards the new favorite value to the repository")
    func forwardsFavoriteValue() throws {
        let repository = FakeUserRepository()
        let sut = DefaultToggleFavoriteUseCase(repository: repository)
        let user = User(name: "Ada Lovelace", email: "ada@example.com", isFavorite: false)

        try sut.execute(user: user, isFavorite: true)

        #expect(repository.favoriteUpdates.count == 1)
        #expect(repository.favoriteUpdates.first?.user === user)
        #expect(user.isFavorite == true)
    }
}

@Suite("RemoveUserUseCase")
struct RemoveUserUseCaseTests {
    @Test("removes the given user from the repository")
    func removesUser() throws {
        let repository = FakeUserRepository()
        let user = User(name: "Ada Lovelace", email: "ada@example.com")
        repository.storedUsers = [user]
        let sut = DefaultRemoveUserUseCase(repository: repository)

        try sut.execute(user: user)

        #expect(repository.storedUsers.isEmpty)
    }
}
