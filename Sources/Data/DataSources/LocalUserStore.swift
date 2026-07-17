import Foundation
import Domain

/// In-memory cache standing in for a local database (e.g. SwiftData/SQLite).
/// It is the single source of truth for favorite state and newly created
/// users: every mutation is broadcast to observers, so any screen watching
/// the cache stays in sync without manual callbacks between features.
actor LocalUserStore {
    private var usersByID: [User.ID: User] = [:]
    private var continuations: [UUID: AsyncStream<[User]>.Continuation] = [:]

    /// Emits the current snapshot immediately, then again after every mutation.
    /// Supports any number of concurrent observers.
    func observe() -> AsyncStream<[User]> {
        let (stream, continuation) = AsyncStream.makeStream(of: [User].self)
        let id = UUID()
        continuations[id] = continuation
        continuation.onTermination = { [weak self] _ in
            Task { await self?.removeObserver(id) }
        }
        continuation.yield(allUsers())
        return stream
    }

    func cache(_ users: [User]) {
        for user in users {
            // Never overwrite a locally-known favorite with stale remote data.
            let existingFavorite = usersByID[user.id]?.isFavorite ?? user.isFavorite
            var merged = user
            merged.isFavorite = existingFavorite
            usersByID[user.id] = merged
        }
        broadcast()
    }

    func cache(_ user: User) {
        usersByID[user.id] = user
        broadcast()
    }

    func user(id: User.ID) -> User? {
        usersByID[id]
    }

    func allUsers() -> [User] {
        usersByID.values.sorted { $0.name < $1.name }
    }

    func setFavorite(id: User.ID, isFavorite: Bool) {
        usersByID[id]?.isFavorite = isFavorite
        broadcast()
    }

    private func broadcast() {
        let users = allUsers()
        for continuation in continuations.values {
            continuation.yield(users)
        }
    }

    private func removeObserver(_ id: UUID) {
        continuations[id] = nil
    }
}
