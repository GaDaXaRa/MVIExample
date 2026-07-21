import Foundation

/// Domain-owned contract. The Data layer implements this; Presentation only
/// ever talks to use cases, never to this protocol or to Data directly.
///
/// Main-actor (the module default) rather than `Sendable`: `@Model` objects
/// are not `Sendable`, and every consumer (stores, use cases) already lives
/// on the main actor. The contract is mutations plus one point read: views
/// observe lists via `@Query`, but resolving a single entity by id (a deep
/// link carries an id, not an object) needs an explicit lookup.
public protocol UserRepository {
    /// Pulls the remote list and upserts it into local storage.
    func refreshUsers() async throws
    func addUser(name: String, email: String) async throws -> User
    func setFavorite(_ user: User, isFavorite: Bool) throws
    /// `nil` removes the relation.
    func setRelated(_ related: User?, for user: User) throws
    /// Resolves a stored user by id (`nil` if none). Used to turn a deep
    /// link's id into a navigable `User`.
    func user(id: UUID) throws -> User?
    /// Deletes the user from local storage.
    func remove(_ user: User) throws
}
