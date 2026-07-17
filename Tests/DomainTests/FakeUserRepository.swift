import Domain

/// A test double for `UserRepository`. `@MainActor` like the protocol itself:
/// `@Model` objects are main-actor-bound, so the contract is too.
@MainActor
final class FakeUserRepository: UserRepository {
    var errorToThrow: Error?
    private(set) var refreshCalls = 0
    private(set) var addUserCalls: [(name: String, email: String)] = []
    private(set) var favoriteUpdates: [(user: User, isFavorite: Bool)] = []

    func refreshUsers() async throws {
        if let errorToThrow { throw errorToThrow }
        refreshCalls += 1
    }

    func addUser(name: String, email: String) async throws -> User {
        if let errorToThrow { throw errorToThrow }
        addUserCalls.append((name, email))
        return User(name: name, email: email)
    }

    func setFavorite(_ user: User, isFavorite: Bool) throws {
        if let errorToThrow { throw errorToThrow }
        user.isFavorite = isFavorite
        favoriteUpdates.append((user, isFavorite))
    }
}
