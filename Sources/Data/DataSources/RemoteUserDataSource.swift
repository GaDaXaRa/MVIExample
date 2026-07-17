import Foundation

/// Abstraction over "the network". Kept as a protocol so tests can swap in a
/// fake without touching the real actor below.
protocol RemoteUserDataSource: Sendable {
    func fetchUsers() async throws -> [UserDTO]
    func createUser(name: String, email: String) async throws -> UserDTO
}

/// An `actor` because a real implementation would own mutable state (URLSession
/// tasks, caches, in-flight request de-duplication); actor isolation makes that
/// state safe to share across concurrent callers without manual locking.
actor MockRemoteUserDataSource: RemoteUserDataSource {
    // Fixed UUIDs: the local store persists across launches now, so the
    // "server" must return stable identities or every launch would duplicate
    // the seed users instead of merging into the existing rows.
    private static let seed: [UserDTO] = [
        UserDTO(id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!, name: "Ada Lovelace", email: "ada@example.com", isFavorite: false),
        UserDTO(id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!, name: "Alan Turing", email: "alan@example.com", isFavorite: true),
        UserDTO(id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!, name: "Grace Hopper", email: "grace@example.com", isFavorite: false)
    ]

    func fetchUsers() async throws -> [UserDTO] {
        try await Task.sleep(for: .milliseconds(400)) // simulated network latency
        return Self.seed
    }

    func createUser(name: String, email: String) async throws -> UserDTO {
        try await Task.sleep(for: .milliseconds(200))
        return UserDTO(id: UUID(), name: name, email: email, isFavorite: false)
    }
}
