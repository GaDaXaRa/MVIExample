// swift-tools-version: 6.2
import PackageDescription

// Default isolation flipped to MainActor (SE-0466, "Approachable Concurrency"):
// in an app, almost everything — views, stores, navigation, @Model entities —
// lives on the main actor, so that is the default and concurrency is opt-in.
// Anything that must run elsewhere says so explicitly (`actor`, `nonisolated`).
let mainActorByDefault: [SwiftSetting] = [.defaultIsolation(MainActor.self)]

let package = Package(
    name: "MVIExample",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "Domain", targets: ["Domain"]),
        .library(name: "Data", targets: ["Data"]),
        .library(name: "Presentation", targets: ["Presentation"])
    ],
    dependencies: [
        // The domain-agnostic MVI + Wireframe kit, published as its own package
        // so it can't reach back into any app layer and is reusable as-is.
        .package(url: "https://github.com/GaDaXaRa/swift-wireframe.git", from: "1.0.0"),
        // Enables `swift package generate-documentation` for the Presentation
        // DocC catalog (the canonical architecture docs). Build/test don't need
        // it; it only powers the docs command and Pages publishing.
        .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.4.3")
    ],
    targets: [
        // MARK: - Domain (entities, use cases, repository protocols). No dependencies: the innermost circle.
        .target(name: "Domain", swiftSettings: mainActorByDefault),

        // MARK: - Data (DTOs, data sources, repository implementations). Depends only on Domain.
        .target(name: "Data", dependencies: ["Domain"], swiftSettings: mainActorByDefault),

        // MARK: - Presentation (MVI features on the Wireframe kit). Depends on Domain + Wireframe, never on Data.
        .target(
            name: "Presentation",
            dependencies: ["Domain", .product(name: "Wireframe", package: "swift-wireframe")],
            swiftSettings: mainActorByDefault
        ),

        // The App composition root (Sources/App) is built by the native Xcode target
        // generated from project.yml, not by this package — an SPM executableTarget
        // can't produce an installable, simulator-runnable .app bundle. See project.yml.

        .testTarget(name: "DomainTests", dependencies: ["Domain"], swiftSettings: mainActorByDefault),
        .testTarget(name: "DataTests", dependencies: ["Data", "Domain"], swiftSettings: mainActorByDefault),
        .testTarget(
            name: "PresentationTests",
            dependencies: ["Presentation", "Domain", .product(name: "Wireframe", package: "swift-wireframe")],
            swiftSettings: mainActorByDefault
        )
    ]
)
