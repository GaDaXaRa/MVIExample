public protocol FetchUserDetailUseCase: Sendable {
    func execute(id: User.ID) async throws -> User
}

public struct DefaultFetchUserDetailUseCase: FetchUserDetailUseCase {
    private let repository: UserRepository

    public init(repository: UserRepository) {
        self.repository = repository
    }

    public func execute(id: User.ID) async throws -> User {
        try await repository.fetchUser(id: id)
    }
}
