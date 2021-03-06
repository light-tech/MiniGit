// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MiniGit",
    platforms: [
        .iOS(.v14),
        .macOS(.v11)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "XGit",
            targets: ["XGit"]),
        .library(
            name: "MiniGit",
            targets: ["MiniGit"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "XGit",
            dependencies: ["libgit2"],
            exclude: ["internal"]),
        .target(
            name: "MiniGit",
            dependencies: ["XGit"],
            linkerSettings: [.linkedLibrary("z"), .linkedLibrary("iconv")]),
        .binaryTarget(
            name: "libgit2",
            url: "https://github.com/light-tech/LibGit2-On-iOS/releases/download/v1.3.1/libgit2.xcframework.zip",
            checksum: "332bfb255649f2295d5530e4abed4e81803acdc6abf18a266695fdb447ca3df2"),
        .testTarget(
            name: "MiniGitTests",
            dependencies: ["MiniGit"]),
    ],
    cxxLanguageStandard: .cxx14
)
