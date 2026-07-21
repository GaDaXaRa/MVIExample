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

@Suite("SetRelatedUserUseCase")
struct SetRelatedUserUseCaseTests {
    @Test("forwards the relation to the repository")
    func forwardsRelation() throws {
        let repository = FakeUserRepository()
        let sut = DefaultSetRelatedUserUseCase(repository: repository)
        let user = User(name: "Ada Lovelace", email: "ada@example.com")
        let related = User(name: "Alan Turing", email: "alan@example.com")

        try sut.execute(user: user, related: related)

        #expect(user.related === related)
        #expect(repository.relationUpdates.count == 1)
    }

    @Test("nil clears the relation")
    func nilClearsRelation() throws {
        let repository = FakeUserRepository()
        let sut = DefaultSetRelatedUserUseCase(repository: repository)
        let user = User(name: "Ada Lovelace", email: "ada@example.com")
        user.related = User(name: "Alan Turing", email: "alan@example.com")

        try sut.execute(user: user, related: nil)

        #expect(user.related == nil)
    }

    @Test("rejects relating a user to themselves")
    func rejectsSelfRelation() throws {
        let repository = FakeUserRepository()
        let sut = DefaultSetRelatedUserUseCase(repository: repository)
        let user = User(name: "Ada Lovelace", email: "ada@example.com")

        #expect(throws: UserRelationError.selfRelation) {
            try sut.execute(user: user, related: user)
        }
        #expect(repository.relationUpdates.isEmpty)
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
