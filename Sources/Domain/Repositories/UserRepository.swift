import Foundation

/// Domain-owned contract. The Data layer implements this; Presentation only
/// ever talks to use cases, never to this protocol or to Data directly.
///
/// `@MainActor` instead of `Sendable`: `@Model` objects are not `Sendable`,
/// and every consumer (stores, use cases) already lives on the main actor.
/// Note there is no "read" operation — views observe storage directly via
/// `@Query`, so the contract only covers mutations.
@MainActor
public protocol UserRepository {
    /// Pulls the remote list and upserts it into local storage.
    func refreshUsers() async throws
    func addUser(name: String, email: String) async throws -> User
    func setFavorite(_ user: User, isFavorite: Bool) throws
}
