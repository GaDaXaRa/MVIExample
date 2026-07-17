import SwiftUI

@main
struct MVIExampleApp: App {
    private let composition = CompositionRoot()

    var body: some Scene {
        WindowGroup {
            RootView(composition: composition)
                .modelContainer(composition.modelContainer)
        }
    }
}
