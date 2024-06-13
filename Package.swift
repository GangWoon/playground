// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "playground",
  platforms: [.iOS(.v17)],
  products: [
    .library(name: "AppFeature", targets: ["Capsule"])
  ],
  targets: [
    .target(name: "Capsule")
  ],
  swiftLanguageVersions: [.v6]
)
