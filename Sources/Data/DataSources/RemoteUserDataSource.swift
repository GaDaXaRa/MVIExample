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
    private static let seed: [UserDTO] = [
        UserDTO(id: UUID(), name: "Ada Lovelace", email: "ada@example.com", isFavorite: false),
        UserDTO(id: UUID(), name: "Alan Turing", email: "alan@example.com", isFavorite: true),
        UserDTO(id: UUID(), name: "Grace Hopper", email: "grace@example.com", isFavorite: false)
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
