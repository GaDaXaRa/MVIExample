import Foundation
import Domain

/// The wire/storage representation. Kept separate from `User` so that a change
/// in the API or storage format never ripples into the Domain entity.
struct UserDTO: Codable, Sendable {
    let id: UUID
    let name: String
    let email: String
    let isFavorite: Bool

    func toDomain() -> User {
        User(id: id, name: name, email: email, isFavorite: isFavorite)
    }

    init(id: UUID, name: String, email: String, isFavorite: Bool) {
        self.id = id
        self.name = name
        self.email = email
        self.isFavorite = isFavorite
    }

    init(from user: User) {
        id = user.id
        name = user.name
        email = user.email
        isFavorite = user.isFavorite
    }
}
