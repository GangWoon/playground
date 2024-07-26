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
        "TabBar",
        "Animation",
        "Shape"
      ]
    )
  ],
  targets: [
    .target(name: "Concurrency"),
    .target(name: "ScrollView"),
    .target(name: "Animation"),
    .target(name: "TabBar"),
    .target(name: "Shape"),
    .target(name: "ViewHelper")
  ],
  swiftLanguageVersions: [.v6]
)

for item in package.targets {
  if item.name != "ViewHelper" {
    item.dependencies = ["ViewHelper"]
  }
}
