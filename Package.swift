// swift-tools-version: 6.0
// SiteScribeCore — umbrella package for all on-device modules.
// The app shell (App/, generated SiteScribe.xcodeproj) links these products;
// `swift test` exercises every module on macOS with deterministic fakes.
import PackageDescription

let strictSettings: [SwiftSetting] = [
    .enableUpcomingFeature("ExistentialAny"),
]

let package = Package(
    name: "SiteScribeCore",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
    ],
    products: [
        .library(name: "ReportKit", targets: ["ReportKit"]),
        .library(name: "RecognitionKit", targets: ["RecognitionKit"]),
        .library(name: "ExtractionKit", targets: ["ExtractionKit"]),
        .library(name: "StorageKit", targets: ["StorageKit"]),
        .library(name: "CaptureKit", targets: ["CaptureKit"]),
        .library(name: "SyncKit", targets: ["SyncKit"]),
        .library(name: "DesignSystem", targets: ["DesignSystem"]),
        .library(name: "JobsFeature", targets: ["JobsFeature"]),
        .library(name: "CaptureFeature", targets: ["CaptureFeature"]),
        .library(name: "ReviewFeature", targets: ["ReviewFeature"]),
        .library(name: "ReportFeature", targets: ["ReportFeature"]),
    ],
    targets: [
        // MARK: Domain core

        .target(
            name: "ReportKit",
            path: "Packages/ReportKit/Sources",
            resources: [.copy("Resources/home_inspection_general.schema.json")],
            swiftSettings: strictSettings
        ),
        .testTarget(
            name: "ReportKitTests",
            dependencies: ["ReportKit"],
            path: "Packages/ReportKit/Tests",
            swiftSettings: strictSettings
        ),

        // MARK: Deterministic recognition layer

        .target(
            name: "RecognitionKit",
            path: "Packages/RecognitionKit/Sources",
            swiftSettings: strictSettings
        ),
        .testTarget(
            name: "RecognitionKitTests",
            dependencies: ["RecognitionKit"],
            path: "Packages/RecognitionKit/Tests",
            resources: [.copy("Fixtures")],
            swiftSettings: strictSettings
        ),

        // MARK: On-device LLM layer (mocked on CI)

        .target(
            name: "ExtractionKit",
            dependencies: ["ReportKit", "RecognitionKit"],
            path: "Packages/ExtractionKit/Sources",
            swiftSettings: strictSettings
        ),
        .testTarget(
            name: "ExtractionKitTests",
            dependencies: ["ExtractionKit"],
            path: "Packages/ExtractionKit/Tests",
            swiftSettings: strictSettings
        ),

        // MARK: Offline-first store

        .target(
            name: "StorageKit",
            path: "Packages/StorageKit/Sources",
            swiftSettings: strictSettings
        ),
        .testTarget(
            name: "StorageKitTests",
            dependencies: ["StorageKit"],
            path: "Packages/StorageKit/Tests",
            swiftSettings: strictSettings
        ),

        // MARK: Capture pipeline (persist first, then process)

        .target(
            name: "CaptureKit",
            dependencies: ["StorageKit", "RecognitionKit", "ExtractionKit", "ReportKit"],
            path: "Packages/CaptureKit/Sources",
            swiftSettings: strictSettings
        ),
        .testTarget(
            name: "CaptureKitTests",
            dependencies: ["CaptureKit"],
            path: "Packages/CaptureKit/Tests",
            resources: [.copy("Fixtures")],
            swiftSettings: strictSettings
        ),

        // MARK: Sync (only module ever allowed to touch the network; M1 ships none)

        .target(
            name: "SyncKit",
            dependencies: ["StorageKit"],
            path: "Packages/SyncKit/Sources",
            swiftSettings: strictSettings
        ),
        .testTarget(
            name: "SyncKitTests",
            dependencies: ["SyncKit"],
            path: "Packages/SyncKit/Tests",
            swiftSettings: strictSettings
        ),

        // MARK: Jobsite Instrument design tokens

        .target(
            name: "DesignSystem",
            path: "Packages/DesignSystem/Sources",
            swiftSettings: strictSettings
        ),
        .testTarget(
            name: "DesignSystemTests",
            dependencies: ["DesignSystem"],
            path: "Packages/DesignSystem/Tests",
            swiftSettings: strictSettings
        ),

        // MARK: Features (SwiftUI)

        .target(
            name: "JobsFeature",
            dependencies: ["StorageKit", "DesignSystem"],
            path: "Packages/Features/JobsFeature/Sources",
            swiftSettings: strictSettings
        ),
        .testTarget(
            name: "JobsFeatureTests",
            dependencies: ["JobsFeature"],
            path: "Packages/Features/JobsFeature/Tests",
            swiftSettings: strictSettings
        ),
        .target(
            name: "CaptureFeature",
            dependencies: ["CaptureKit", "StorageKit", "DesignSystem"],
            path: "Packages/Features/CaptureFeature/Sources",
            resources: [.copy("SampleCaptures")],
            swiftSettings: strictSettings
        ),
        .testTarget(
            name: "CaptureFeatureTests",
            dependencies: ["CaptureFeature"],
            path: "Packages/Features/CaptureFeature/Tests",
            swiftSettings: strictSettings
        ),
        .target(
            name: "ReviewFeature",
            dependencies: ["ReportKit", "DesignSystem"],
            path: "Packages/Features/ReviewFeature/Sources",
            swiftSettings: strictSettings
        ),
        .testTarget(
            name: "ReviewFeatureTests",
            dependencies: ["ReviewFeature"],
            path: "Packages/Features/ReviewFeature/Tests",
            swiftSettings: strictSettings
        ),
        .target(
            name: "ReportFeature",
            dependencies: ["ReportKit", "DesignSystem"],
            path: "Packages/Features/ReportFeature/Sources",
            swiftSettings: strictSettings
        ),
        .testTarget(
            name: "ReportFeatureTests",
            dependencies: ["ReportFeature"],
            path: "Packages/Features/ReportFeature/Tests",
            swiftSettings: strictSettings
        ),
    ]
)
