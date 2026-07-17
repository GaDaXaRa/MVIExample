import SwiftUI

/// A route is a small `Hashable` **value** describing a destination screen —
/// it says *what* to show, never *how*. The presentation mode (push, sheet,
/// fullscreen cover) is chosen by whoever sends the `RouterIntent`, and the
/// destination view itself never knows which one was used.
///
/// `nonisolated` (opting out of the module's MainActor default) because route
/// values are inert identifiers: conformers must be `nonisolated` too, so
/// their synthesized `Hashable` never crosses an isolation boundary.
public nonisolated protocol Route: Hashable {}

/// Type-erased wrapper so heterogeneous route values can travel through one
/// `NavigationPath` and one sheet/cover slot. Equality delegates to the
/// wrapped route's value equality, which is what makes `popTo` work.
public struct AnyRoute: Hashable, Identifiable {
    public let route: any Route
    private let box: AnyHashable

    public init(_ route: any Route) {
        self.route = route
        self.box = AnyHashable(route)
    }

    public var id: AnyHashable { box }

    public static func == (lhs: AnyRoute, rhs: AnyRoute) -> Bool {
        lhs.box == rhs.box
    }

    public func hash(into hasher: inout Hasher) {
        box.hash(into: &hasher)
    }
}

/// A system alert, described as a value so flows can trigger it like any
/// other presentation — the wireframe owns the `.alert` modifier.
public struct AlertContent: Equatable {
    public let title: String
    public let message: String?

    public init(title: String, message: String? = nil) {
        self.title = title
        self.message = message
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
    /// The caller picks the presentation; the destination never knows which:
    case push(any Route)
    case sheet(any Route)
    /// Fullscreen cover (no-op on macOS, which has no `fullScreenCover`).
    case present(any Route)
    case alert(AlertContent)

    case pop
    case popToRoot
    /// Pops everything above the most recent occurrence of the given route.
    case popTo(any Route)
    /// Dismisses the modal this wireframe presented — or, when it presented
    /// nothing, the modal *containing* it (the intent bubbles to the parent).
    case dismiss
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
    public private(set) var routes: [AnyRoute] = []

    public var presentedSheet: AnyRoute?
    public var presentedCover: AnyRoute?
    public var presentedAlert: AlertContent?

    /// SwiftUI's `.alert` wants a `Bool` binding; deriving it keeps
    /// `presentedAlert` as the single source of truth.
    public var isAlertPresented: Bool {
        get { presentedAlert != nil }
        set { if !newValue { presentedAlert = nil } }
    }

    /// Every modal gets its own child wireframe (its own stack, modals and
    /// alerts); `dismiss` bubbles up through this chain, so a screen deep
    /// inside a modal can close it without knowing who presented it.
    private let parent: AppRouter?

    public init(parent: AppRouter? = nil) {
        self.parent = parent
    }

    public func send(_ intent: RouterIntent) {
        switch intent {
        case .push(let route):
            let wrapped = AnyRoute(route)
            routes.append(wrapped)
            path.append(wrapped)
        case .sheet(let route):
            presentedSheet = AnyRoute(route)
        case .present(let route):
            presentedCover = AnyRoute(route)
        case .alert(let alert):
            presentedAlert = alert
        case .pop:
            guard !path.isEmpty else { return }
            path.removeLast()
        case .popToRoot:
            path.removeLast(path.count)
        case .popTo(let route):
            guard let index = routes.lastIndex(of: AnyRoute(route)) else { return }
            path.removeLast(routes.count - index - 1)
        case .dismiss:
            if presentedSheet != nil || presentedCover != nil {
                presentedSheet = nil
                presentedCover = nil
            } else {
                parent?.send(.dismiss)
            }
        }
    }
}
