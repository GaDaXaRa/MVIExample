// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MVIExample",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "Domain", targets: ["Domain"]),
        .library(name: "Data", targets: ["Data"]),
        .library(name: "Presentation", targets: ["Presentation"])
    ],
    targets: [
        // MARK: - Domain (entities, use cases, repository protocols). No dependencies: the innermost circle.
        .target(name: "Domain"),

        // MARK: - Data (DTOs, data sources, repository implementations). Depends only on Domain.
        .target(name: "Data", dependencies: ["Domain"]),

        // MARK: - Presentation (MVI: State, Intent, Store + SwiftUI views). Depends only on Domain, never on Data.
        .target(name: "Presentation", dependencies: ["Domain"]),

        // The App composition root (Sources/App) is built by the native Xcode target
        // generated from project.yml, not by this package — an SPM executableTarget
        // can't produce an installable, simulator-runnable .app bundle. See project.yml.

        .testTarget(name: "DomainTests", dependencies: ["Domain"]),
        .testTarget(name: "DataTests", dependencies: ["Data", "Domain"]),
        .testTarget(name: "PresentationTests", dependencies: ["Presentation", "Domain"])
    ]
)
