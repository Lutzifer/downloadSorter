// swift-tools-version:4.0

import PackageDescription

let package = Package(
  name: "DownloadSorter",
  dependencies: [
    .package(
      url: "https://github.com/kylef/Commander.git",
      from: "0.8.0"
    )
  ],
  targets: [
    .target(
      name: "DownloadSorter",
      dependencies: [
        "DownloadSorterCore",
        "Commander"
      ]
    ),
    .target(
      name: "DownloadSorterCore",
      dependencies: []
    ),
    .testTarget(
      name: "DownloadSorterTests",
      dependencies: ["DownloadSorterCore"]
    )
  ]
)
