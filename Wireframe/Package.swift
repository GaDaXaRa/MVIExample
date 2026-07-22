// swift-tools-version: 6.2
import PackageDescription

// Domain-agnostic app-shell kit: the MVI contract (Store), the intent-based
// Router + WireframeView + DestinationRegistry, and the SessionStore gate.
// It knows nothing about any app's entities, so any app can depend on it.
let package = Package(
    name: "Wireframe",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "Wireframe", targets: ["Wireframe"])
    ],
    targets: [
        .target(
            name: "Wireframe",
            swiftSettings: [.defaultIsolation(MainActor.self)]
        ),
        .testTarget(
            name: "WireframeTests",
            dependencies: ["Wireframe"],
            swiftSettings: [.defaultIsolation(MainActor.self)]
        )
    ]
)
