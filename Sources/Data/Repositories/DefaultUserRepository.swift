import Foundation
import SwiftData
import Domain

/// Implements the Domain-owned `UserRepository` contract on top of SwiftData's
/// main context plus a remote source. There is no separate cache type any
/// more: the `ModelContext` *is* the local storage, and `@Query` on the view
/// side replaces hand-rolled change broadcasting.
public final class DefaultUserRepository: UserRepository {
    private let context: ModelContext
    private let remote: RemoteUserDataSource

    init(context: ModelContext, remote: RemoteUserDataSource) {
        self.context = context
        self.remote = remote
    }

    /// Convenience factory: the concrete remote source is an implementation
    /// detail of this module, so the composition root only provides the context.
    public static func live(context: ModelContext) -> DefaultUserRepository {
        DefaultUserRepository(context: context, remote: MockRemoteUserDataSource())
    }

    public func refreshUsers() async throws {
        let dtos = try await remote.fetchUsers()
        let existingByID = Dictionary(
            uniqueKeysWithValues: try context.fetch(FetchDescriptor<User>()).map { ($0.id, $0) }
        )
        for dto in dtos {
            if let user = existingByID[dto.id] {
                // Never overwrite a locally-known favorite with stale remote data.
                user.name = dto.name
                user.email = dto.email
            } else {
                context.insert(dto.toDomain)
            }
        }
        try context.save()
    }

    public func addUser(name: String, email: String) async throws -> User {
        let dto = try await remote.createUser(name: name, email: email)
        let user = dto.toDomain
        context.insert(user)
        try context.save()
        return user
    }

    public func setFavorite(_ user: User, isFavorite: Bool) throws {
        user.isFavorite = isFavorite
        try context.save()
    }

    public func setRelated(_ related: User?, for user: User) throws {
        user.related = related
        try context.save()
    }

    public func user(id: UUID) throws -> User? {
        try context.fetch(FetchDescriptor<User>(predicate: #Predicate { $0.id == id })).first
    }
    
    public func remove(_ user: User) throws {
        context.delete(user)
        try context.save()
    }
}

private extension UserDTO {
    var toDomain: User {
        User(id: id, name: name, email: email, isFavorite: isFavorite)
    }
}
