import Foundation

/// Core business entity. Pure data, no framework dependencies.
public struct User: Identifiable, Equatable, Sendable, Codable {
    public let id: UUID
    public var name: String
    public var email: String
    public var isFavorite: Bool

    public init(id: UUID = UUID(), name: String, email: String, isFavorite: Bool = false) {
        self.id = id
        self.name = name
        self.email = email
        self.isFavorite = isFavorite
    }
}
