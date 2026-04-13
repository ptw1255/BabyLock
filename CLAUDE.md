# CLAUDE.md

## Project

BabyLock — an iOS app that acts as a touch-blocking shield over playing content so parents can hand their iPhone to a baby/toddler without worry.

## Architecture

- **SwiftUI** for parent-facing UI (browser, media picker, settings, passcode setup)
- **UIKit** for child mode (fullscreen lock, touch-blocking overlay, system gesture deferral)
- **Share Extension** receives URLs from Safari/other apps via custom URL scheme `babylock://open?url=...`
- Minimum deployment target: **iOS 17**

## Key Files

- `BabyLock/App/` — App entry point and shared state
- `BabyLock/Parent/` — All parent-mode SwiftUI views
- `BabyLock/ChildMode/` — UIKit child-mode controller, touch overlay, unlock gesture
- `BabyLock/Shared/` — Passcode storage (Keychain), reusable passcode entry view
- `BabyLock/ShareExtension/` — Share Extension target

## Conventions

- No third-party dependencies. Use only Apple frameworks.
- No analytics, no network calls, no accounts. The app is entirely local.
- Passcode stored in Keychain, never UserDefaults.
- WKWebView navigation delegate must block app-redirect URL schemes (`youtube://`, `twitter://`, etc.).
- Child mode must set: `prefersStatusBarHidden`, `prefersHomeIndicatorAutoHidden`, `preferredScreenEdgesDeferringSystemGestures` returning `.all`, and `isIdleTimerDisabled = true`.

## Testing

- Unit tests for passcode storage, URL scheme parsing, unlock gesture logic
- UI tests for lock/unlock flow, share extension handoff

## Design Spec

Full design spec at: `docs/specs/2026-04-13-babylock-ios-app-design.md`
