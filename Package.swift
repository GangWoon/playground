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
        "TabBar"
      ]
    )
  ],
  targets: [
    .target(name: "Concurrency"),
    .target(name: "ScrollView"),
    .target(name: "TabBar")
  ],
  swiftLanguageVersions: [.v6]
)
