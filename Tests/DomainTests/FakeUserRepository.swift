import Domain

/// A test double for `UserRepository`. It's an `actor` for the same reason the
/// real implementation is: the protocol requires `Sendable`, and tests call
/// its methods from concurrent test tasks.
actor FakeUserRepository: UserRepository {
    private var usersToReturn: [User] = []
    var errorToThrow: Error?
    private(set) var addUserCalls: [(name: String, email: String)] = []
    private(set) var favoriteUpdates: [(id: User.ID, isFavorite: Bool)] = []

    func set(usersToReturn: [User]) {
        self.usersToReturn = usersToReturn
    }

    func observeUsers() async -> AsyncStream<[User]> {
        let usersToReturn = usersToReturn
        return AsyncStream { continuation in
            continuation.yield(usersToReturn)
            continuation.finish()
        }
    }

    func fetchUsers() async throws -> [User] {
        if let errorToThrow { throw errorToThrow }
        return usersToReturn
    }

    func fetchUser(id: User.ID) async throws -> User {
        if let errorToThrow { throw errorToThrow }
        guard let user = usersToReturn.first(where: { $0.id == id }) else {
            throw UserRepositoryError.notFound
        }
        return user
    }

    func addUser(name: String, email: String) async throws -> User {
        if let errorToThrow { throw errorToThrow }
        addUserCalls.append((name, email))
        return User(name: name, email: email)
    }

    func setFavorite(id: User.ID, isFavorite: Bool) async throws {
        if let errorToThrow { throw errorToThrow }
        favoriteUpdates.append((id, isFavorite))
    }
}
