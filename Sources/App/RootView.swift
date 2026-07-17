import SwiftUI
import Presentation

/// The app's outermost switch: login gate over the main tabs. When the
/// session expires — at any moment, even with modals on screen — the whole
/// content is replaced by the login screen; because navigation state lives in
/// the composition's routers, everything (stacks, sheets, covers) is restored
/// exactly as it was once the user logs back in.
struct RootView: View {
    let composition: CompositionRoot

    var body: some View {
        if composition.session.isAuthenticated {
            TabView {
                ForEach(composition.tabs) { tab in
                    WireframeView(router: tab.router, registry: composition.registry) {
                        UserListView(store: composition.makeUserListStore(router: tab.router))
                    }
                    .tabItem {
                        Label(tab.title, systemImage: tab.systemImage)
                    }
                }
            }
        } else {
            LoginView(store: composition.makeLoginStore())
        }
    }
}
