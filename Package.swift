// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "playground",
  platforms: [.iOS(.v17)],
  products: [
    .library(name: "Concurrency", targets: ["Concurrency"]),
    .library(
      name: "Views",
      targets: [
        "ScrollView",
        "Animation",
        "etc"
      ]
    )
  ],
  targets: [
    .target(name: "Concurrency"),
    .testTarget(
      name: "ConcurrencyTests",
      dependencies: ["Concurrency"]
    ),
    .target(
      name: "ScrollView",
      dependencies: ["ViewHelper"]
    ),
    .target(
      name: "Animation",
      dependencies: ["ViewHelper"]
    ),
    .target(
      name: "etc",
      dependencies: ["ViewHelper"]
    ),
    .target(name: "ViewHelper")
  ]
)
