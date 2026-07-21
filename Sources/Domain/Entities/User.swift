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
    /// Self-referential many-to-many relationship: the users this one relates
    /// to. Being a `@Model` property it is observable, so a screen showing the
    /// list re-renders the moment a relation is added or removed elsewhere —
    /// no callbacks between the picker and the detail.
    public var related: [User] = []

    /// Inverse of ``related``: the users who point at this one. Declared so
    /// SwiftData nullifies those references when this user is deleted (removes
    /// it from everyone's `related`), so the relationship has a defined
    /// inverse, and so the related-users list can `@Query` for "users related
    /// to X" (a user U is in `target.related` iff `target` is in `U.relatedBy`).
    @Relationship(deleteRule: .nullify, inverse: \User.related)
    public var relatedBy: [User] = []

    public init(id: UUID = UUID(), name: String, email: String, isFavorite: Bool = false) {
        self.id = id
        self.name = name
        self.email = email
        self.isFavorite = isFavorite
    }
}
