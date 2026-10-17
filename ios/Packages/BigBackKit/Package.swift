// swift-tools-version: 6.0
// BigBackKit: the app's modules (docs/architecture/01-technical-architecture.md §2.2).
// Features depend on BigBackCore protocols and DesignSystem, never on Supabase directly.
import PackageDescription

let package = Package(
    name: "BigBackKit",
    platforms: [.iOS(.v18)],
    products: [
        .library(name: "BigBackCore", targets: ["BigBackCore"]),
        .library(name: "DesignSystem", targets: ["DesignSystem"]),
        .library(name: "BigBackData", targets: ["BigBackData"]),
        .library(name: "Onboarding", targets: ["Onboarding"]),
    ],
    dependencies: [
        .package(url: "https://github.com/supabase/supabase-swift", from: "2.0.0"),
    ],
    targets: [
        .target(name: "BigBackCore"),
        .target(name: "DesignSystem"),
        .target(
            name: "BigBackData",
            dependencies: ["BigBackCore", .product(name: "Supabase", package: "supabase-swift")]
        ),
        .target(name: "Onboarding", dependencies: ["BigBackCore", "DesignSystem"]),
        .testTarget(name: "BigBackCoreTests", dependencies: ["BigBackCore"]),
    ]
)
