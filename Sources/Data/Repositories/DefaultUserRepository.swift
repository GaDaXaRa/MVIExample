import Domain

/// Implements the Domain-owned `UserRepository` contract by coordinating a
/// remote source and a local cache. Nothing outside this layer knows that
/// two data sources are involved.
public struct DefaultUserRepository: UserRepository {
    private let remote: RemoteUserDataSource
    private let local: LocalUserStore

    init(remote: RemoteUserDataSource, local: LocalUserStore) {
        self.remote = remote
        self.local = local
    }

    /// Convenience factory: the concrete data sources are an implementation
    /// detail of this module, so the public initializer only takes what the
    /// composition root actually needs to decide.
    public static func live() -> DefaultUserRepository {
        DefaultUserRepository(remote: MockRemoteUserDataSource(), local: LocalUserStore())
    }

    public func fetchUsers() async throws -> [User] {
        let dtos = try await remote.fetchUsers()
        await local.cache(dtos.map { $0.toDomain() })
        return await local.allUsers().sorted { $0.name < $1.name }
    }

    public func fetchUser(id: User.ID) async throws -> User {
        guard let user = await local.user(id: id) else {
            throw UserRepositoryError.notFound
        }
        return user
    }

    public func addUser(name: String, email: String) async throws -> User {
        let dto = try await remote.createUser(name: name, email: email)
        let user = dto.toDomain()
        await local.cache(user)
        return user
    }

    public func setFavorite(id: User.ID, isFavorite: Bool) async throws {
        await local.setFavorite(id: id, isFavorite: isFavorite)
    }
}
