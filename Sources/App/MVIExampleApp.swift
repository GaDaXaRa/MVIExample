import SwiftUI
import Presentation

@main
struct MVIExampleApp: App {
    private let composition = CompositionRoot()

    var body: some Scene {
        WindowGroup {
            WireframeView(router: composition.router, registry: composition.registry) {
                UserListView(store: composition.makeUserListStore())
            }
            .modelContainer(composition.modelContainer)
        }
    }
}
