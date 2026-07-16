public protocol ToggleFavoriteUseCase: Sendable {
    func execute(id: User.ID, isFavorite: Bool) async throws
}

public struct DefaultToggleFavoriteUseCase: ToggleFavoriteUseCase {
    private let repository: UserRepository

    public init(repository: UserRepository) {
        self.repository = repository
    }

    public func execute(id: User.ID, isFavorite: Bool) async throws {
        try await repository.setFavorite(id: id, isFavorite: isFavorite)
    }
}
