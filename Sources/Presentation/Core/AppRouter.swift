import SwiftUI

/// A route is a small `Hashable` **value** describing a pushed screen. Each
/// feature defines its own route type and registers the matching view with a
/// `.navigationDestination` extension (see `userDetailDestination`), so there
/// is no central enum of screens — and no type-erased views: because the path
/// carries values, routes stay comparable (`popTo` works by equality) and
/// could be made `Codable` for deep links and state restoration.
///
/// `nonisolated` (opting out of the module's MainActor default) because route
/// values are inert identifiers: conformers must be `nonisolated` too, so
/// their synthesized `Hashable` never crosses an isolation boundary.
public nonisolated protocol Route: Hashable {}

/// Modal presentations are app-scoped and ephemeral (no deep links, no
/// restoration), so a plain enum remains the pragmatic choice for them.
public enum Sheet: Identifiable {
    case addUser

    public var id: String {
        switch self {
        case .addUser: return "addUser"
        }
    }
}

/// Navigation gets the same shape as every feature: a closed vocabulary of
/// intents behind a single entry point, mirroring `Store.send`. Stores depend
/// on this protocol — not on the concrete router — so tests can record
/// intents with a spy instead of driving a real navigation stack.
public protocol Router: AnyObject {
    func send(_ intent: RouterIntent)
}

public enum RouterIntent {
    case push(any Route)
    case pop
    case popToRoot
    /// Pops everything above the most recent occurrence of the given route.
    case popTo(any Route)
    case present(Sheet)
    case dismissSheet
}

@Observable
public final class AppRouter: Router {
    /// `NavigationPath` stores the route values type-erased, which is what
    /// lets every feature push its own route type without a shared enum.
    public var path = NavigationPath() {
        didSet {
            // Interactive pops (back button, edge swipe) shrink the path
            // through the view's binding, bypassing `send`; truncate the
            // mirror to the same depth so `popTo` stays accurate.
            if path.count < routes.count {
                routes.removeLast(routes.count - path.count)
            }
        }
    }

    /// Mirror of the pushed routes: `NavigationPath` is opaque (no element
    /// access), and `popTo` needs to locate a route's position.
    public private(set) var routes: [AnyHashable] = []

    public var presentedSheet: Sheet?

    public init() {}

    public func send(_ intent: RouterIntent) {
        switch intent {
        case .push(let route):
            routes.append(AnyHashable(route))
            path.append(route)
        case .pop:
            guard !path.isEmpty else { return }
            path.removeLast()
        case .popToRoot:
            path.removeLast(path.count)
        case .popTo(let route):
            guard let index = routes.lastIndex(of: AnyHashable(route)) else { return }
            path.removeLast(routes.count - index - 1)
        case .present(let sheet):
            presentedSheet = sheet
        case .dismissSheet:
            presentedSheet = nil
        }
    }
}
