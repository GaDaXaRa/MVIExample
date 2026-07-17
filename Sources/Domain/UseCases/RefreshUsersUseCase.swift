/// A use case is a single, named business operation. Stores call use cases,
/// never repositories directly, so business rules stay out of the Presentation layer.
@MainActor
public protocol RefreshUsersUseCase {
    func execute() async throws
}

public struct DefaultRefreshUsersUseCase: RefreshUsersUseCase {
    private let repository: UserRepository

    public init(repository: UserRepository) {
        self.repository = repository
    }

    public func execute() async throws {
        try await repository.refreshUsers()
    }
}
