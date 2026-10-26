// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "MapplsUtils",

    platforms: [
        .iOS(.v13)
    ],

    products: [
        .library(
            name: "MapplsUtils",
            targets: [
                "MapplsUtils"
            ]
        )
    ],

    targets: [
        .binaryTarget(
            name: "MapplsUtils",
            url: "https://mmi-api-team.s3.amazonaws.com/Mappls-SDKs/iOS_Legacy_Auth/MapplsUtils/MapplsUtils.xcframework-1.0.2.zip",
            checksum: "a770bc73f44d7f51ebcf60f5a9ea2756405dddaac655fa6be61fc52d28126fa2"
        )
    ]
)
