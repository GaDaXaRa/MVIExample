import Foundation

/// The wire/storage representation. Kept separate from `User` so that a change
/// in the API or storage format never ripples into the Domain entity.
struct UserDTO: Codable, Sendable {
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
