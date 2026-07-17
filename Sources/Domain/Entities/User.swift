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

    public init(id: UUID = UUID(), name: String, email: String, isFavorite: Bool = false) {
        self.id = id
        self.name = name
        self.email = email
        self.isFavorite = isFavorite
    }
}
