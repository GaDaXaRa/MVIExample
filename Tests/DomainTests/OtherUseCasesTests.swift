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
