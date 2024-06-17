// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "playground",
  platforms: [.iOS(.v17)],
  products: [
    .library(name: "Concurrency", targets: ["Concurrency"]),
  ],
  targets: [
    .target(name: "Concurrency")
  ],
  swiftLanguageVersions: [.v6]
)
