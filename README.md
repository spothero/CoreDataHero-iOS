# CoreDataHero-iOS

[![CI Status](https://github.com/spothero/CoreDataHero-iOS/workflows/CI/badge.svg)](https://github.com/spothero/CoreDataHero-iOS/actions?query=workflow%3A%22CI%22)
[![Latest Release](https://img.shields.io/github/v/tag/spothero/CoreDataHero-iOS?color=blue&label=latest)](https://github.com/spothero/CoreDataHero-iOS/releases)
[![Swift Version](https://img.shields.io/static/v1?label=swift&message=5.2&color=red&logo=swift&logoColor=white)](https://developer.apple.com/swift)
[![Platform Support](https://img.shields.io/static/v1?label=platform&message=iOS%20|%20macOS%20|%20watchOS%20|%20tvOS&color=darkgray)](https://github.com/spothero/CoreDataHero-iOS/blob/main/Package.swift)
[![License](https://img.shields.io/github/license/spothero/CoreDataHero-iOS)](https://github.com/spothero/CoreDataHero-iOS/blob/main/LICENSE)

CoreDataHero is a lightweight package for setting up and managing a Core Data stack.

>:warning: The code in this library has been provided as-is. SpotHero uses this library in Production, but it may lack the documentation, stability, and functionality necessary to support external use. While we work on improving this codebase, **use this library at your own risk** and please [reach out](#communication) if you have any questions or feedback.

- [Installation](#installation)
- [Communication](#communication)

## Installation

### Swift Package Manager

[Swift Package Manager](https://swift.org/package-manager/) is built into the Swift toolchain and is our preferred way of integrating the SDK.

For Swift package projects, simply add the following line to your `Package.swift` file in the `dependencies` section:

```swift
dependencies: [
  .package(url: "https://github.com/spothero/CoreDataHero-iOS", .upToNextMajor(from: "<version>")),
]
```

For app projects, simply follow the [Apple documentation](https://developer.apple.com/documentation/xcode/adding_package_dependencies_to_your_app) on adding package dependencies to your app.

## Communication

For all bug reports, feature requests, and general communication, please open an issue to get in contact with us.
