import SwiftUI
import Presentation

/// The app's outermost switch: login gate over the main tabs. When the
/// session expires — at any moment, even with modals on screen — the whole
/// content is replaced by the login screen; because navigation state lives in
/// the composition's routers, everything (stacks, sheets, covers) is restored
/// exactly as it was once the user logs back in.
struct RootView: View {
    let composition: CompositionRoot
    @Bindable private var deepLink: DeepLinkCoordinator

    init(composition: CompositionRoot) {
        self.composition = composition
        self.deepLink = composition.deepLink
    }

    var body: some View {
        content
            // Incoming deep links: a URL becomes an ordinary route on a tab's
            // router. Arriving while logged out, it is held and applied here
            // the moment the session opens.
            .onOpenURL { deepLink.open($0) }
            .onChange(of: composition.session.isAuthenticated) { _, isAuthenticated in
                if isAuthenticated { deepLink.resumePending() }
            }
    }

    @ViewBuilder
    private var content: some View {
        if composition.session.isAuthenticated {
            TabView(selection: $deepLink.selectedTab) {
                ForEach(Array(composition.tabs.enumerated()), id: \.offset) { index, tab in
                    WireframeView(router: tab.router, registry: composition.registry) {
                        UserListView(store: composition.makeUserListStore(router: tab.router))
                    }
                    .tabItem {
                        Label(tab.title, systemImage: tab.systemImage)
                    }
                    .tag(index)
                }
            }
        } else {
            LoginView(store: composition.makeLoginStore())
        }
    }
}
