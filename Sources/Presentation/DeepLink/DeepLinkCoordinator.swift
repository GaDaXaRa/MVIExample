import Foundation
import Wireframe
import Observation
import Domain

/// Turns a ``DeepLink`` into ordinary navigation on the existing routers. This
/// is where routes-as-values pays off: the coordinator builds the very same
/// `Route` value the in-app flows build (`UserDetailRoute`, `AddUserRoute`),
/// hands it to the tab's `AppRouter`, and the registry/wireframe present it —
/// there is no deep-link-specific presentation code at all.
///
/// A link arriving while logged out is held pending and applied on login, so a
/// session gate never drops an incoming URL.
@Observable
@MainActor
public final class DeepLinkCoordinator {
    /// Bound by the root `TabView`, so a link can bring its tab to the front.
    public var selectedTab: Int = 0

    private let routers: [AppRouter]
    private let session: SessionStore
    private let fetchUser: FetchUserUseCase
    private var pending: DeepLink?

    public init(routers: [AppRouter], session: SessionStore, fetchUser: FetchUserUseCase) {
        self.routers = routers
        self.session = session
        self.fetchUser = fetchUser
    }

    public func open(_ url: URL) {
        guard let link = DeepLink(url: url) else { return }
        open(link)
    }

    public func open(_ link: DeepLink) {
        guard session.isAuthenticated else {
            pending = link
            return
        }
        apply(link)
    }

    /// Called by the root view once the session becomes authenticated.
    public func resumePending() {
        guard let link = pending else { return }
        pending = nil
        apply(link)
    }

    private func apply(_ link: DeepLink) {
        // Every supported link targets the browsing tab; a real app would map
        // links to tabs. Bringing it to the front makes the result visible.
        let targetTab = 0
        selectedTab = targetTab
        let router = routers[targetTab]

        switch link {
        case .users:
            router.send(.popToRoot)
        case .user(let id):
            guard let user = try? fetchUser.execute(id: id) else { return }
            router.send(.popToRoot)
            router.send(.push(UserDetailRoute(user: user)))
        case .addUser:
            router.send(.sheet(AddUserRoute()))
        }
    }
}
