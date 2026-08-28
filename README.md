# BabyLock

BabyLock is an iOS 17+ prototype for loading web or local media and temporarily making the in-app experience inert before handing a device to a young child. It combines a SwiftUI parent flow with a UIKit child mode, a center-hold unlock gesture, Keychain-backed passcode verification, and guidance for Apple's Guided Access. Device-level containment still depends on Guided Access; the app does not claim to replace it. The implementation is grounded in [`project.yml`](project.yml), [`BabyLock/Parent/ParentView.swift`](BabyLock/Parent/ParentView.swift), and [`BabyLock/ChildMode/ChildModeController.swift`](BabyLock/ChildMode/ChildModeController.swift).

## Status

Portfolio prototype. The repository includes an app target, share extension, and unit-test target, but it does not include release, adoption, or outcome evidence.

## Product portfolio

The [product case study and decision artifacts](docs/product/README.md) explain the user problem, jobs to be done, value proposition, opportunity costs, experience wireframes, and evidence-gated roadmap.

## Verified project pointers

- XcodeGen configuration and iOS target: [`project.yml`](project.yml)
- Product and platform design: [`docs/specs/2026-04-13-babylock-ios-app-design.md`](docs/specs/2026-04-13-babylock-ios-app-design.md)
- Unit tests: [`BabyLockTests/`](BabyLockTests/)
