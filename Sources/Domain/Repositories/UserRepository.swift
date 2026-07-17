import Foundation

/// Domain-owned contract. The Data layer implements this; Presentation only ever
/// talks to use cases, never to this protocol or to Data directly.
public protocol UserRepository: Sendable {
    /// Long-lived stream of the locally-known users: yields the current
    /// snapshot on subscription and again after every mutation (favorite
    /// toggles, newly added users, remote refreshes).
    func observeUsers() async -> AsyncStream<[User]>
    func fetchUsers() async throws -> [User]
    func fetchUser(id: User.ID) async throws -> User
    func addUser(name: String, email: String) async throws -> User
    func setFavorite(id: User.ID, isFavorite: Bool) async throws
}

public enum UserRepositoryError: Error, LocalizedError, Sendable {
    case notFound

    public var errorDescription: String? {
        switch self {
        case .notFound: return "User not found."
        }
    }
}
