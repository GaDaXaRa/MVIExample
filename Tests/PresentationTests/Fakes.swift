import Domain

// Lightweight use case fakes: each Presentation test only needs to control
// one operation's result, so a small Sendable struct/class is enough — no
// need to go through a full fake repository as the Domain/Data tests do.

/// Hands the store a stream the test controls: `emit` simulates the repository
/// broadcasting a change (remote refresh, favorite toggle, new user).
final class FakeObserveUsersUseCase: ObserveUsersUseCase, @unchecked Sendable {
    private let stream: AsyncStream<[User]>
    private let continuation: AsyncStream<[User]>.Continuation

    init() {
        (stream, continuation) = AsyncStream.makeStream(of: [User].self)
    }

    func execute() async -> AsyncStream<[User]> {
        stream
    }

    func emit(_ users: [User]) {
        continuation.yield(users)
    }
}

struct FakeFetchUsersUseCase: FetchUsersUseCase {
    var usersToReturn: [User] = []
    var errorToThrow: (any Error & Sendable)?

    func execute() async throws -> [User] {
        if let errorToThrow { throw errorToThrow }
        return usersToReturn
    }
}

struct FakeFetchUserDetailUseCase: FetchUserDetailUseCase {
    var userToReturn: User?
    var errorToThrow: (any Error & Sendable)?

    func execute(id: User.ID) async throws -> User {
        if let errorToThrow { throw errorToThrow }
        guard let userToReturn else { throw UserRepositoryError.notFound }
        return userToReturn
    }
}

final class FakeToggleFavoriteUseCase: ToggleFavoriteUseCase, @unchecked Sendable {
    var errorToThrow: (any Error & Sendable)?
    private(set) var calls: [(id: User.ID, isFavorite: Bool)] = []

    func execute(id: User.ID, isFavorite: Bool) async throws {
        calls.append((id, isFavorite))
        if let errorToThrow { throw errorToThrow }
    }
}

struct FakeAddUserUseCase: AddUserUseCase {
    var userToReturn: User?
    var errorToThrow: (any Error & Sendable)?

    func execute(name: String, email: String) async throws -> User {
        if let errorToThrow { throw errorToThrow }
        return userToReturn ?? User(name: name, email: email)
    }
}
