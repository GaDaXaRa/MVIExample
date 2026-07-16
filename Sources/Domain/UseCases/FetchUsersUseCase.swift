/// A use case is a single, named business operation. Stores call use cases,
/// never repositories directly, so business rules stay out of the Presentation layer.
public protocol FetchUsersUseCase: Sendable {
    func execute() async throws -> [User]
}

public struct DefaultFetchUsersUseCase: FetchUsersUseCase {
    private let repository: UserRepository

    public init(repository: UserRepository) {
        self.repository = repository
    }

    public func execute() async throws -> [User] {
        try await repository.fetchUsers()
    }
}
