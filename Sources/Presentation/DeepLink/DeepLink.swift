import Foundation

/// A parsed deep link: the URL reduced to a value, before it is resolved into
/// a navigable `Route`. Kept separate from routes because a URL only carries
/// identifiers (`mviexample://user/<uuid>`), while a route carries the
/// resolved `User`.
public enum DeepLink: Equatable {
    case users
    case user(UUID)
    case addUser

    /// Parses `mviexample://users`, `mviexample://user/<uuid>`,
    /// `mviexample://add-user`. Returns `nil` for anything unrecognized.
    public init?(url: URL) {
        guard url.scheme == "mviexample" else { return nil }
        switch url.host {
        case "users":
            self = .users
        case "user":
            guard let id = url.pathComponents.last.flatMap(UUID.init(uuidString:)) else { return nil }
            self = .user(id)
        case "add-user":
            self = .addUser
        default:
            return nil
        }
    }
}
