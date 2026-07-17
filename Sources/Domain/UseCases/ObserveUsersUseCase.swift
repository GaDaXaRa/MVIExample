/// Exposes the repository's user stream to Presentation. Any store that keeps
/// users on screen consumes this instead of holding its own stale snapshot,
/// so a change made from one feature is reflected everywhere automatically.
public protocol ObserveUsersUseCase: Sendable {
    func execute() async -> AsyncStream<[User]>
}

public struct DefaultObserveUsersUseCase: ObserveUsersUseCase {
    private let repository: UserRepository

    public init(repository: UserRepository) {
        self.repository = repository
    }

    public func execute() async -> AsyncStream<[User]> {
        await repository.observeUsers()
    }
}
