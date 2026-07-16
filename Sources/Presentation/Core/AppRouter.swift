import Observation
import Domain

/// Navigation is a side effect, not application state: it doesn't describe
/// "what the screen looks like", so it is deliberately kept out of every
/// feature's `State` and lives in its own observable object instead. Intent
/// handlers call into it directly when a navigation Intent arrives.
@Observable
@MainActor
public final class AppRouter {
    public enum Route: Hashable {
        case userDetail(User.ID)
    }

    public enum Sheet: Identifiable {
        case addUser
        public var id: String {
            switch self {
            case .addUser: return "addUser"
            }
        }
    }

    public var path: [Route] = []
    public var presentedSheet: Sheet?

    public init() {}

    public func push(_ route: Route) {
        path.append(route)
    }

    public func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    public func present(_ sheet: Sheet) {
        presentedSheet = sheet
    }

    public func dismissSheet() {
        presentedSheet = nil
    }
}
