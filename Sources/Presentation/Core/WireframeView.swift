import SwiftUI

/// The "wireframe": a superior view that owns every presentation container —
/// the `NavigationStack`, the sheet and the fullscreen cover — and resolves
/// routes through the `DestinationRegistry` at presentation time.
///
/// Destination views are completely presentation-agnostic: they carry no
/// `NavigationStack`, no dismiss logic and no knowledge of how they appear.
/// Modal contents get their own `NavigationStack` here, so toolbars work the
/// same whether a screen was pushed or presented.
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
                    registry.view(for: wrapped.route)
                }
        }
        .sheet(item: $router.presentedSheet) { wrapped in
            NavigationStack {
                registry.view(for: wrapped.route)
            }
        }
        #if !os(macOS)
        .fullScreenCover(item: $router.presentedCover) { wrapped in
            NavigationStack {
                registry.view(for: wrapped.route)
            }
        }
        #endif
    }
}
