public protocol ToggleFavoriteUseCase {
    func execute(user: User, isFavorite: Bool) throws
}

public struct DefaultToggleFavoriteUseCase: ToggleFavoriteUseCase {
    private let repository: UserRepository

    public init(repository: UserRepository) {
        self.repository = repository
    }

    public func execute(user: User, isFavorite: Bool) throws {
        try repository.setFavorite(user, isFavorite: isFavorite)
    }
}
