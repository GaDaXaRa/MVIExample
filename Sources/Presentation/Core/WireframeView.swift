import SwiftUI

/// The "wireframe": a superior view that owns every presentation container —
/// the `NavigationStack`, the sheet, the fullscreen cover and the alert — and
/// resolves routes through the `DestinationRegistry` at presentation time.
///
/// Destination views are completely presentation-agnostic: they carry no
/// `NavigationStack`, no dismiss logic and no knowledge of how they appear.
/// Each modal it presents is a **child wireframe** with its own router, so
/// modals get their own navigation stack, their own modals and their own
/// alerts, and `dismiss` bubbles from child to parent.
public struct WireframeView<Content: View>: View {
    @Bindable private var router: AppRouter
    private let registry: DestinationRegistry
    private let content: Content

    public init(
        router: AppRouter,
        registry: DestinationRegistry,
        @ViewBuilder content: () -> Content
    ) {
        self.router = router
        self.registry = registry
        self.content = content()
    }

    public var body: some View {
        NavigationStack(path: $router.path) {
            content
                .navigationDestination(for: AnyRoute.self) { wrapped in
                    registry.view(for: wrapped.route, router: router)
                }
        }
        .sheet(item: $router.presentedSheet) { wrapped in
            ChildWireframeView(parent: router, registry: registry, route: wrapped)
        }
        #if !os(macOS)
        .fullScreenCover(item: $router.presentedCover) { wrapped in
            ChildWireframeView(parent: router, registry: registry, route: wrapped)
        }
        #endif
        .alert(
            router.presentedAlert?.title ?? "",
            isPresented: $router.isAlertPresented,
            presenting: router.presentedAlert
        ) { _ in
            Button("OK") {}
        } message: { alert in
            if let message = alert.message {
                Text(message)
            }
        }
    }
}

/// Modal content wrapped in a wireframe of its own. The fresh router's
/// lifetime is tied to the presentation (`@State`), and its `parent` link is
/// what lets `dismiss` bubble up and close the modal that contains it.
private struct ChildWireframeView: View {
    @State private var router: AppRouter
    private let registry: DestinationRegistry
    private let route: AnyRoute

    init(parent: AppRouter, registry: DestinationRegistry, route: AnyRoute) {
        _router = State(initialValue: AppRouter(parent: parent))
        self.registry = registry
        self.route = route
    }

    var body: some View {
        WireframeView(router: router, registry: registry) {
            registry.view(for: route.route, router: router)
        }
    }
}
