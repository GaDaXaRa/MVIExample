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
                makeDetailStore: { user in composition.makeUserDetailStore(user: user) },
                makeAddUserStore: { composition.makeAddUserStore(router: router) }
            )
            .modelContainer(composition.modelContainer)
        }
    }
}
