# BabyLock iOS App — Design Spec

## Problem

Parents hand their iPhone to a baby/toddler (0-3) to watch a video at a restaurant, in the car, etc. The child inevitably taps something, exits the video, opens settings, calls someone, or otherwise disrupts the experience. The parent keeps having to grab the phone back and fix it.

## Solution

An iOS app that acts as a **dumb shield** over whatever content is playing. It does not manage, control, or understand the content — it only blocks all touch interaction until the parent intentionally unlocks it.

## Target

- **Age range:** 0-3 (babies/toddlers)
- **Primary device:** iPhone
- **Secondary device:** iPad
- **Minimum iOS:** 17

## Architecture: SwiftUI Shell + UIKit Core

Parent-facing UI is SwiftUI for fast iteration and modern feel. Child mode (the lock) is UIKit for direct access to system gesture deferral, touch interception, and fullscreen immersion APIs.

---

## App Modes

### Parent Mode (default)

The unlocked state. Parent loads content and activates the lock.

**Content loading — three paths:**

1. **Share Extension (primary workflow)**
   - Parent is in Safari, finds a YouTube video, taps Share, selects "BabyLock"
   - Share Extension extracts the URL and opens the main app via custom URL scheme (`babylock://open?url=...`)
   - Main app loads the URL in WKWebView, video plays
   - Parent taps the Lock button

2. **In-app browser (fallback)**
   - Simple WKWebView with address bar, back/forward, reload
   - Parent navigates to any URL directly
   - Parent taps the Lock button

3. **Local media**
   - PHPicker (Apple's standard photo/video picker)
   - Video loads in AVPlayer, photo loads in UIImageView
   - Parent taps the Lock button

**Settings screen (passcode-gated):**
- Change passcode (4-6 digits)
- Guided Access tutorial (step-by-step instructions with images)
- Nothing else

**First launch flow:**
- Set a 4-6 digit passcode (required before anything else works)
- Brief one-screen explainer of how the app works

### Child Mode (locked)

Fullscreen, immersive, completely inert. The child sees the content and nothing else.

**Layer stack (bottom to top):**

1. **Content layer** — WKWebView (web video) or AVPlayer (local video) or UIImageView (local photo), filling the entire screen
2. **Touch-absorbing overlay** — transparent UIView covering the entire screen, intercepting and discarding every touch event. Nothing reaches the content below.
3. **Unlock gesture recognizer** — attached to the overlay. Single finger, held stationary within a 150pt-radius circle centered on the screen for 5 continuous seconds. If the finger moves more than 20pt from its initial touch point, lifts, or a second finger touches, the timer resets.

**System-level protections:**
- `prefersStatusBarHidden` returns `true` — no status bar
- `prefersHomeIndicatorAutoHidden` returns `true` — home indicator fades away
- `preferredScreenEdgesDeferringSystemGestures` returns `.all` — Control Center, Notification Center, and home gesture all require a double-swipe
- `UIApplication.shared.isIdleTimerDisabled = true` — screen stays on indefinitely

**Touch behavior:** Total dead zone. Touches produce no visual feedback, no sound, no effect of any kind.

**Unlock flow:**
1. Parent holds center of screen for 5 continuous seconds
2. A subtle progress ring fades in (visible to parent who knows to look, invisible to child who doesn't)
3. Passcode screen appears
4. Correct passcode → child mode exits, back to parent mode
5. Wrong passcode → back to child mode, overlay resets

---

## Guided Access Integration

The app cannot programmatically lock the device to itself — this is a hard iOS platform constraint. Only Apple's built-in Guided Access feature (or MDM) can do this.

The app's role:
- After the first lock activation, show a one-time tutorial: "For full protection, enable Guided Access" with step-by-step instructions (Settings > Accessibility > Guided Access > On, then triple-click side button)
- Small reminder accessible from settings, but no nagging
- Detect Guided Access status via `UIAccessibility.isGuidedAccessEnabled` and suppress the tutorial when already active

**With Guided Access enabled:** The child cannot exit the app at all. Combined with the touch-blocking overlay, the device is fully locked to the playing content. The only escape is the parent unlocking (5-sec hold + passcode) or restarting the device.

**Without Guided Access:** The app's overlay blocks all touches within the app, and system gestures require double-swipe, but a persistent toddler could eventually swipe home. Good enough for most situations, but Guided Access is the complete solution.

---

## Project Structure

```
BabyLock/
├── App/
│   ├── BabyLockApp.swift          # SwiftUI app entry point
│   └── AppState.swift             # Observable state: mode, passcode, content source
├── Parent/
│   ├── ParentView.swift           # Main parent screen (SwiftUI)
│   ├── BrowserView.swift          # WKWebView wrapper (UIViewRepresentable)
│   ├── MediaPickerView.swift      # PHPicker wrapper
│   ├── SettingsView.swift         # Passcode change, Guided Access tutorial
│   └── PasscodeSetupView.swift    # First-launch passcode creation
├── ChildMode/
│   ├── ChildModeController.swift  # UIKit VC: fullscreen, gesture deferral, status bar
│   ├── TouchBlockingOverlay.swift # UIView that swallows all touches
│   └── UnlockGesture.swift        # 5-sec long press recognizer + progress ring
├── Shared/
│   ├── PasscodeStore.swift        # Keychain-backed passcode storage
│   └── PasscodeEntryView.swift    # Reusable passcode input (unlock + settings)
├── ShareExtension/
│   └── ShareViewController.swift  # Receives URLs, opens main app via URL scheme
└── Resources/
    └── GuidedAccessTutorial/      # Tutorial images and copy
```

---

## Key Technical Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| UI framework | SwiftUI (parent) + UIKit (child mode) | SwiftUI for fast UI iteration, UIKit for system-level lock APIs |
| Passcode storage | Keychain | Encrypted at rest, survives reinstall |
| Share mechanism | Share Extension + custom URL scheme | Standard iOS "open with" pattern |
| WKWebView navigation | Delegate blocks app-redirect schemes | Prevents `youtube://` etc. from escaping to other apps |
| Video player | AVPlayer with `showsPlaybackControls = false` in child mode | No dismiss gesture, no visible controls |
| Touch blocking | Transparent UIView overlay | Explicit control over every touch event |
| Idle timer | Disabled in child mode | Screen stays on for the child |
| Analytics/network | None | Entirely local, nothing leaves the device |
| Minimum iOS | 17 | Modern SwiftUI, ~95% active device coverage |

---

## Data Flow

```
Share Sheet → URL scheme → App opens → WKWebView loads URL
                                            │
                            Parent taps Lock button
                                            │
                                            ▼
                    ChildModeController presented fullscreen
                    (overlay absorbs touches, gestures deferred)
                                            │
                        5-sec hold → passcode prompt → unlock
                                            │
                                            ▼
                    ChildModeController dismissed → back to parent
```

---

## What This App Is NOT

- **Not a content manager.** It does not know or care what is playing, whether it ended, or what comes next.
- **Not a parental control app.** It does not use the Screen Time API, FamilyControls, or MDM.
- **Not a kids' content app.** It has no built-in games, animations, or sounds.
- **Not a replacement for Guided Access.** It complements Guided Access by providing the content loading and touch blocking; Guided Access provides the device-level lock.

## What This App IS

A fast, minimal tool that lets a parent load content, tap one button, and hand the phone to their child with confidence that nothing will be disrupted.
