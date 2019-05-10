// swift-tools-version:4.2
import PackageDescription

let package = Package(
    name: "Expression",
    products: [
        .library(name: "Expression", targets: ["Expression"]),
    ],
    targets: [
        .target(name: "Expression", path: "Sources"),
        .testTarget(name: "ExpressionTests", dependencies: ["Expression"], path: "Tests"),
    ]
)
