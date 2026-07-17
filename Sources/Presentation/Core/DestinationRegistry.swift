import SwiftUI

/// Maps route types to their view builders. The composition root registers
/// every feature's destination exactly once; `WireframeView` resolves a route
/// to its view at presentation time. Because resolution is independent of the
/// presentation mode, the same route — and therefore the same view — can be
/// pushed, shown as a sheet or as a fullscreen cover interchangeably.
///
/// Builders receive the `Router` of the wireframe doing the presenting, so a
/// destination's flow always talks to the navigation context it actually
/// lives in — a screen inside a modal dismisses *that* modal, not the tab
/// underneath it.
///
/// This is the one place where type erasure happens (`AnyView`): a registry
/// of heterogeneous view builders cannot be typed, and a screen boundary is
/// where erasure costs nothing.
public final class DestinationRegistry {
    private var builders: [ObjectIdentifier: (any Route, any Router) -> AnyView] = [:]

    public init() {}

    public func register<R: Route>(
        _ type: R.Type,
        @ViewBuilder _ builder: @escaping (R, any Router) -> some View
    ) {
        builders[ObjectIdentifier(type)] = { route, router in
            AnyView(builder(route as! R, router))
        }
    }

    func view(for route: any Route, router: any Router) -> AnyView {
        guard let builder = builders[ObjectIdentifier(type(of: route))] else {
            assertionFailure("No destination registered for route type \(type(of: route))")
            return AnyView(EmptyView())
        }
        return builder(route, router)
    }
}
