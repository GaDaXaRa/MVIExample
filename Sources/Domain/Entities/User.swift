import Foundation
import SwiftData

/// Core business entity, now a SwiftData `@Model`. One type is simultaneously:
/// - the persistence schema (SwiftData storage),
/// - the observable object views react to (a favorite toggled anywhere
///   re-renders every screen showing this user — no streams, no callbacks),
/// - the navigation payload (`PersistentModel` is `Hashable`/`Identifiable`).
///
/// Deliberate trade-off: Domain imports SwiftData, in exchange for deleting
/// the DTO↔entity mapping, the local cache actor and all hand-rolled change
/// propagation between features.
@Model
public final class User {
    public private(set) var id: UUID
    public var name: String
    public var email: String
    public var isFavorite: Bool
    /// Self-referential to-one relationship. Being a `@Model` property, any
    /// screen showing this user re-renders when the relation changes — the
    /// modal picker that sets it needs no callback to the detail screen.
    public var related: User?

    /// Inverse of ``related``: the users who point at this one. Declared only
    /// so SwiftData can nullify those references when this user is deleted —
    /// a self-referential to-one has no inverse otherwise, and the delete
    /// would leave a dangling reference. Internal: nothing outside Domain
    /// needs "who refers to me".
    @Relationship(deleteRule: .nullify, inverse: \User.related)
    var relatedBy: [User] = []

    public init(id: UUID = UUID(), name: String, email: String, isFavorite: Bool = false) {
        self.id = id
        self.name = name
        self.email = email
        self.isFavorite = isFavorite
    }
}
