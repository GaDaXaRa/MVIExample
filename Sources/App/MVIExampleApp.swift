import SwiftUI
import Presentation

@main
struct MVIExampleApp: App {
    @State private var router = AppRouter()
    private let composition = CompositionRoot()

    var body: some Scene {
        WindowGroup {
            UserListView(
                router: router,
                store: composition.makeUserListStore(router: router),
                makeDetailStore: { id in composition.makeUserDetailStore(userID: id, router: router) },
                makeAddUserStore: { composition.makeAddUserStore(router: router) }
            )
        }
    }
}
