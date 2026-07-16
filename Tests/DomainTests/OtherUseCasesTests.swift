import Testing
import Foundation
@testable import Domain

@Suite("FetchUsersUseCase")
struct FetchUsersUseCaseTests {
    @Test("returns whatever the repository returns")
    func passesThroughRepositoryResult() async throws {
        let repository = FakeUserRepository()
        await repository.set(usersToReturn: [User(name: "Grace Hopper", email: "grace@example.com")])
        let sut = DefaultFetchUsersUseCase(repository: repository)

        let users = try await sut.execute()

        #expect(users.map(\.name) == ["Grace Hopper"])
    }
}

@Suite("ToggleFavoriteUseCase")
struct ToggleFavoriteUseCaseTests {
    @Test("forwards the new favorite value to the repository")
    func forwardsFavoriteValue() async throws {
        let repository = FakeUserRepository()
        let sut = DefaultToggleFavoriteUseCase(repository: repository)
        let id = UUID()

        try await sut.execute(id: id, isFavorite: true)

        let updates = await repository.favoriteUpdates
        #expect(updates.count == 1)
        #expect(updates.first?.id == id)
        #expect(updates.first?.isFavorite == true)
    }
}
