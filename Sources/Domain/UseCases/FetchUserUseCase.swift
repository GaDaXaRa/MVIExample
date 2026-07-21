import Foundation

/// Resolves a single user by id. The one read use case, used by deep-link
/// handling to turn a URL's id into a `User` the navigation can present.
public protocol FetchUserUseCase {
    func execute(id: UUID) throws -> User?
}

public struct DefaultFetchUserUseCase: FetchUserUseCase {
    private let repository: UserRepository

    public init(repository: UserRepository) {
        self.repository = repository
    }

    public func execute(id: UUID) throws -> User? {
        try repository.user(id: id)
    }
}
