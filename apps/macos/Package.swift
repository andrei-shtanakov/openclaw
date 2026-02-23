// swift-tools-version: 6.2
// Package manifest for the Orchid macOS companion (menu bar app + IPC library).

import PackageDescription

let package = Package(
    name: "Orchid",
    platforms: [
        .macOS(.v15),
    ],
    products: [
        .library(name: "OrchidIPC", targets: ["OrchidIPC"]),
        .library(name: "OrchidDiscovery", targets: ["OrchidDiscovery"]),
        .executable(name: "Orchid", targets: ["Orchid"]),
        .executable(name: "orchid-mac", targets: ["OrchidMacCLI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/orchetect/MenuBarExtraAccess", exact: "1.2.2"),
        .package(url: "https://github.com/swiftlang/swift-subprocess.git", from: "0.1.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.8.0"),
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.8.1"),
        .package(url: "https://github.com/steipete/Peekaboo.git", branch: "main"),
        .package(path: "../shared/OrchidKit"),
        .package(path: "../../Swabble"),
    ],
    targets: [
        .target(
            name: "OrchidIPC",
            dependencies: [],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
            ]),
        .target(
            name: "OrchidDiscovery",
            dependencies: [
                .product(name: "OrchidKit", package: "OrchidKit"),
            ],
            path: "Sources/OrchidDiscovery",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
            ]),
        .executableTarget(
            name: "Orchid",
            dependencies: [
                "OrchidIPC",
                "OrchidDiscovery",
                .product(name: "OrchidKit", package: "OrchidKit"),
                .product(name: "OrchidChatUI", package: "OrchidKit"),
                .product(name: "OrchidProtocol", package: "OrchidKit"),
                .product(name: "SwabbleKit", package: "swabble"),
                .product(name: "MenuBarExtraAccess", package: "MenuBarExtraAccess"),
                .product(name: "Subprocess", package: "swift-subprocess"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "Sparkle", package: "Sparkle"),
                .product(name: "PeekabooBridge", package: "Peekaboo"),
                .product(name: "PeekabooAutomationKit", package: "Peekaboo"),
            ],
            exclude: [
                "Resources/Info.plist",
            ],
            resources: [
                .copy("Resources/Orchid.icns"),
                .copy("Resources/DeviceModels"),
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
            ]),
        .executableTarget(
            name: "OrchidMacCLI",
            dependencies: [
                "OrchidDiscovery",
                .product(name: "OrchidKit", package: "OrchidKit"),
                .product(name: "OrchidProtocol", package: "OrchidKit"),
            ],
            path: "Sources/OrchidMacCLI",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
            ]),
        .testTarget(
            name: "OrchidIPCTests",
            dependencies: [
                "OrchidIPC",
                "Orchid",
                "OrchidDiscovery",
                .product(name: "OrchidProtocol", package: "OrchidKit"),
                .product(name: "SwabbleKit", package: "swabble"),
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
                .enableExperimentalFeature("SwiftTesting"),
            ]),
    ])
