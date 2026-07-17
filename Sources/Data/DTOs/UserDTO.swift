import Foundation

/// The wire representation. Kept separate from `User` so that a change in the
/// API format never ripples into the Domain entity. `nonisolated` opts out of
/// the module's MainActor default: DTOs are plain values built inside the
/// remote actor and carried across the concurrency boundary.
nonisolated struct UserDTO: Codable, Sendable {
    let id: UUID
    let name: String
    let email: String
    let isFavorite: Bool

    init(id: UUID, name: String, email: String, isFavorite: Bool) {
        self.id = id
        self.name = name
        self.email = email
        self.isFavorite = isFavorite
    }
}
