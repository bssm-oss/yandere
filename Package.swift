// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "WeekendRain",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "WeekendRainCore", targets: ["WeekendRainCore"]),
        .executable(name: "WeekendRain", targets: ["WeekendRain"]),
        .executable(name: "WeekendRainValidation", targets: ["WeekendRainValidation"])
    ],
    targets: [
        .target(
            name: "WeekendRainCore",
            path: "WeekendRain",
            exclude: ["App"],
            sources: ["Models", "Engine", "Views", "Backlog", "Gallery"]
        ),
        .executableTarget(
            name: "WeekendRain",
            dependencies: ["WeekendRainCore"],
            path: "WeekendRain/App",
            exclude: ["Info.plist", "AppIcon.icns", "AppIconSource.png"],
            sources: ["main.swift", "AppDelegate.swift", "MainWindowController.swift"]
        ),
        .executableTarget(
            name: "WeekendRainValidation",
            dependencies: ["WeekendRainCore"],
            path: "Validation",
            sources: ["main.swift"]
        )
    ]
)
