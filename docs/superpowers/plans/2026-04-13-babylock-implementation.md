# BabyLock Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build an iOS app that acts as a touch-blocking shield over playing content, letting parents hand their iPhone to a toddler without worry.

**Architecture:** SwiftUI shell for parent-facing UI (browser, media picker, settings), UIKit core for child mode (fullscreen lock, touch overlay, system gesture deferral). Share Extension receives URLs from Safari. Content views (WKWebView, AVPlayer) are shared instances that transfer between parent and child mode without reloading.

**Tech Stack:** Swift, SwiftUI, UIKit, WebKit (WKWebView), AVKit (AVPlayer), PhotosUI (PHPicker), Security (Keychain). Zero third-party dependencies. XcodeGen for project generation.

---

## File Map

```
BabyLock/                          ← Xcode project root
├── project.yml                    ← XcodeGen project definition
├── .gitignore                     ← iOS gitignore
├── BabyLock/                      ← Main app target
│   ├── App/
│   │   ├── BabyLockApp.swift      ← @main entry, URL scheme handling
│   │   └── AppState.swift         ← @Observable: mode, content, passcode state
│   ├── ContentManager/
│   │   └── ContentManager.swift   ← Owns shared WKWebView + AVPlayer instances
│   ├── Parent/
│   │   ├── ParentView.swift       ← Main parent screen: browser + toolbar
│   │   ├── BrowserView.swift      ← UIViewRepresentable wrapping shared WKWebView
│   │   ├── BrowserToolbar.swift   ← Address bar, back/forward/reload, media + settings + lock buttons
│   │   ├── MediaPlayerView.swift  ← UIViewRepresentable for AVPlayer + UIImageView
│   │   ├── SettingsView.swift     ← Passcode change + Guided Access tutorial
│   │   └── PasscodeSetupView.swift← First-launch passcode creation
│   ├── ChildMode/
│   │   ├── ChildModeController.swift  ← UIKit VC: fullscreen, gesture deferral, status bar, idle timer
│   │   ├── TouchBlockingOverlay.swift ← UIView that swallows all touches
│   │   └── UnlockGestureRecognizer.swift ← 5-sec center hold + progress ring
│   └── Shared/
│       ├── PasscodeStore.swift    ← Keychain CRUD for passcode
│       ├── PasscodeEntryView.swift← Reusable SwiftUI passcode input
│       └── URLSchemeHandler.swift ← Parse babylock://open?url=... URLs
├── BabyLockShareExtension/        ← Share Extension target
│   └── ShareViewController.swift  ← Extracts URL, saves to App Group, opens main app
└── BabyLockTests/                 ← Unit test target
    ├── PasscodeStoreTests.swift
    ├── URLSchemeHandlerTests.swift
    └── UnlockGestureTests.swift
```

---

## Task 1: Project Scaffold

**Files:**
- Create: `project.yml`
- Create: `.gitignore`
- Create: `BabyLock/App/BabyLockApp.swift`
- Create: `BabyLockShareExtension/ShareViewController.swift` (stub)
- Create: `BabyLockTests/PlaceholderTest.swift`

- [ ] **Step 1: Install XcodeGen**

Run: `brew list xcodegen || brew install xcodegen`

Expected: XcodeGen installed and available on PATH.

- [ ] **Step 2: Create .gitignore**

Create `.gitignore`:

```gitignore
# Xcode
*.xcodeproj/xcuserdata/
*.xcworkspace/xcuserdata/
DerivedData/
build/
*.pbxuser
*.mode1v3
*.mode2v3
*.perspectivev3
*.hmap
*.ipa
*.dSYM.zip
*.dSYM
*.xcuserstate

# Resolved packages
*.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/
.build/

# OS
.DS_Store
```

- [ ] **Step 3: Create project.yml**

Create `project.yml`:

```yaml
name: BabyLock
options:
  bundleIdPrefix: com.ptw1255
  deploymentTarget:
    iOS: "17.0"
  generateEmptyDirectories: true
settings:
  base:
    SWIFT_VERSION: "5.9"
    TARGETED_DEVICE_FAMILY: "1,2"
targets:
  BabyLock:
    type: application
    platform: iOS
    sources:
      - path: BabyLock
    info:
      properties:
        CFBundleDisplayName: BabyLock
        CFBundleURLTypes:
          - CFBundleURLSchemes:
              - babylock
        UILaunchScreen: {}
        UISupportedInterfaceOrientations:
          - UIInterfaceOrientationPortrait
          - UIInterfaceOrientationLandscapeLeft
          - UIInterfaceOrientationLandscapeRight
        NSPhotoLibraryUsageDescription: "BabyLock needs access to your photos and videos to play them for your child."
    entitlements:
      properties:
        com.apple.security.application-groups:
          - group.com.ptw1255.BabyLock
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.ptw1255.BabyLock
    dependencies:
      - target: BabyLockShareExtension
        embed: true
  BabyLockShareExtension:
    type: app-extension
    platform: iOS
    sources:
      - path: BabyLockShareExtension
    info:
      properties:
        CFBundleDisplayName: BabyLock
        NSExtension:
          NSExtensionPointIdentifier: com.apple.share-services
          NSExtensionPrincipalClass: "$(PRODUCT_MODULE_NAME).ShareViewController"
          NSExtensionActivationRule:
            NSExtensionActivationSupportsWebURLWithMaxCount: 1
    entitlements:
      properties:
        com.apple.security.application-groups:
          - group.com.ptw1255.BabyLock
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.ptw1255.BabyLock.ShareExtension
  BabyLockTests:
    type: bundle.unit-test
    platform: iOS
    sources:
      - path: BabyLockTests
    dependencies:
      - target: BabyLock
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.ptw1255.BabyLockTests
```

- [ ] **Step 4: Create directory structure**

```bash
mkdir -p BabyLock/App
mkdir -p BabyLock/ContentManager
mkdir -p BabyLock/Parent
mkdir -p BabyLock/ChildMode
mkdir -p BabyLock/Shared
mkdir -p BabyLockShareExtension
mkdir -p BabyLockTests
```

- [ ] **Step 5: Create minimal app entry point**

Create `BabyLock/App/BabyLockApp.swift`:

```swift
import SwiftUI

@main
struct BabyLockApp: App {
    var body: some Scene {
        WindowGroup {
            Text("BabyLock")
        }
    }
}
```

- [ ] **Step 6: Create Share Extension stub**

Create `BabyLockShareExtension/ShareViewController.swift`:

```swift
import UIKit
import Social

class ShareViewController: SLComposeServiceViewController {
    override func didSelectPost() {
        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }

    override func configurationItems() -> [Any]! {
        return []
    }
}
```

- [ ] **Step 7: Create placeholder test**

Create `BabyLockTests/PlaceholderTest.swift`:

```swift
import XCTest
@testable import BabyLock

final class PlaceholderTest: XCTestCase {
    func testProjectBuilds() {
        XCTAssertTrue(true)
    }
}
```

- [ ] **Step 8: Generate Xcode project and build**

```bash
cd /path/to/BabyLock
xcodegen generate
xcodebuild build -scheme BabyLock -destination 'platform=iOS Simulator,name=iPhone 16' -quiet
```

Expected: Build succeeds with no errors.

- [ ] **Step 9: Run tests**

```bash
xcodebuild test -scheme BabyLockTests -destination 'platform=iOS Simulator,name=iPhone 16' -quiet
```

Expected: 1 test passes.

- [ ] **Step 10: Commit**

```bash
git add .gitignore project.yml BabyLock/ BabyLockShareExtension/ BabyLockTests/
git commit -m "feat: scaffold BabyLock Xcode project with XcodeGen"
```

---

## Task 2: Passcode Store (Keychain)

**Files:**
- Create: `BabyLock/Shared/PasscodeStore.swift`
- Create: `BabyLockTests/PasscodeStoreTests.swift`
- Delete: `BabyLockTests/PlaceholderTest.swift`

- [ ] **Step 1: Write failing tests**

Create `BabyLockTests/PasscodeStoreTests.swift`:

```swift
import XCTest
@testable import BabyLock

final class PasscodeStoreTests: XCTestCase {
    var store: PasscodeStore!

    override func setUp() {
        super.setUp()
        store = PasscodeStore()
        try? store.delete()
    }

    override func tearDown() {
        try? store.delete()
        super.tearDown()
    }

    func testInitiallyHasNoPasscode() {
        XCTAssertFalse(store.hasPasscode)
        XCTAssertNil(store.load())
    }

    func testSaveAndLoad() throws {
        try store.save("1234")
        XCTAssertEqual(store.load(), "1234")
    }

    func testHasPasscodeAfterSave() throws {
        try store.save("5678")
        XCTAssertTrue(store.hasPasscode)
    }

    func testVerifyCorrectPasscode() throws {
        try store.save("9012")
        XCTAssertTrue(store.verify("9012"))
    }

    func testVerifyWrongPasscode() throws {
        try store.save("9012")
        XCTAssertFalse(store.verify("0000"))
    }

    func testVerifyWithNoPasscodeSet() {
        XCTAssertFalse(store.verify("1234"))
    }

    func testSaveOverwritesPrevious() throws {
        try store.save("1111")
        try store.save("2222")
        XCTAssertEqual(store.load(), "2222")
    }

    func testDeleteRemovesPasscode() throws {
        try store.save("1234")
        try store.delete()
        XCTAssertFalse(store.hasPasscode)
        XCTAssertNil(store.load())
    }

    func testDeleteWhenNoneExistsDoesNotThrow() {
        XCTAssertNoThrow(try store.delete())
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
xcodebuild test -scheme BabyLockTests -destination 'platform=iOS Simulator,name=iPhone 16' -quiet 2>&1 | tail -20
```

Expected: Compilation error — `PasscodeStore` not found.

- [ ] **Step 3: Implement PasscodeStore**

Create `BabyLock/Shared/PasscodeStore.swift`:

```swift
import Foundation
import Security

enum PasscodeStoreError: Error {
    case saveFailed(OSStatus)
    case deleteFailed(OSStatus)
}

final class PasscodeStore {
    private let service = "com.ptw1255.BabyLock"
    private let account = "passcode"

    func save(_ passcode: String) throws {
        let data = Data(passcode.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        // Delete existing before saving
        SecItemDelete(query as CFDictionary)

        var addQuery = query
        addQuery[kSecValueData as String] = data

        let status = SecItemAdd(addQuery as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw PasscodeStoreError.saveFailed(status)
        }
    }

    func load() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    func delete() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw PasscodeStoreError.deleteFailed(status)
        }
    }

    var hasPasscode: Bool {
        load() != nil
    }

    func verify(_ passcode: String) -> Bool {
        load() == passcode
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
xcodebuild test -scheme BabyLockTests -destination 'platform=iOS Simulator,name=iPhone 16' -quiet 2>&1 | tail -20
```

Expected: 9 tests pass.

- [ ] **Step 5: Delete placeholder test and commit**

```bash
rm BabyLockTests/PlaceholderTest.swift
git add BabyLock/Shared/PasscodeStore.swift BabyLockTests/PasscodeStoreTests.swift
git rm BabyLockTests/PlaceholderTest.swift
git commit -m "feat: add Keychain-backed PasscodeStore with tests"
```

---

## Task 3: URL Scheme Handler

**Files:**
- Create: `BabyLock/Shared/URLSchemeHandler.swift`
- Create: `BabyLockTests/URLSchemeHandlerTests.swift`

- [ ] **Step 1: Write failing tests**

Create `BabyLockTests/URLSchemeHandlerTests.swift`:

```swift
import XCTest
@testable import BabyLock

final class URLSchemeHandlerTests: XCTestCase {
    func testParsesValidBabyLockURL() {
        let url = URL(string: "babylock://open?url=https%3A%2F%2Fwww.youtube.com%2Fwatch%3Fv%3Dabc123")!
        let result = URLSchemeHandler.parse(url)
        XCTAssertEqual(result, URL(string: "https://www.youtube.com/watch?v=abc123"))
    }

    func testReturnsNilForWrongScheme() {
        let url = URL(string: "https://example.com")!
        let result = URLSchemeHandler.parse(url)
        XCTAssertNil(result)
    }

    func testReturnsNilForWrongHost() {
        let url = URL(string: "babylock://wrong?url=https%3A%2F%2Fexample.com")!
        let result = URLSchemeHandler.parse(url)
        XCTAssertNil(result)
    }

    func testReturnsNilForMissingURLParam() {
        let url = URL(string: "babylock://open")!
        let result = URLSchemeHandler.parse(url)
        XCTAssertNil(result)
    }

    func testReturnsNilForEmptyURLParam() {
        let url = URL(string: "babylock://open?url=")!
        let result = URLSchemeHandler.parse(url)
        XCTAssertNil(result)
    }

    func testReturnsNilForInvalidURLParam() {
        let url = URL(string: "babylock://open?url=not%20a%20url")!
        let result = URLSchemeHandler.parse(url)
        XCTAssertNil(result)
    }

    func testBuildsBabyLockURL() {
        let contentURL = URL(string: "https://www.youtube.com/watch?v=abc123")!
        let result = URLSchemeHandler.buildOpenURL(for: contentURL)
        XCTAssertEqual(result.scheme, "babylock")
        XCTAssertEqual(result.host, "open")

        // Round-trip: build then parse
        let parsed = URLSchemeHandler.parse(result)
        XCTAssertEqual(parsed, contentURL)
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
xcodebuild test -scheme BabyLockTests -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BabyLockTests/URLSchemeHandlerTests -quiet 2>&1 | tail -20
```

Expected: Compilation error — `URLSchemeHandler` not found.

- [ ] **Step 3: Implement URLSchemeHandler**

Create `BabyLock/Shared/URLSchemeHandler.swift`:

```swift
import Foundation

enum URLSchemeHandler {
    static func parse(_ url: URL) -> URL? {
        guard url.scheme == "babylock",
              url.host == "open",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let urlString = components.queryItems?.first(where: { $0.name == "url" })?.value,
              !urlString.isEmpty,
              let contentURL = URL(string: urlString),
              contentURL.scheme == "https" || contentURL.scheme == "http"
        else {
            return nil
        }
        return contentURL
    }

    static func buildOpenURL(for contentURL: URL) -> URL {
        var components = URLComponents()
        components.scheme = "babylock"
        components.host = "open"
        components.queryItems = [URLQueryItem(name: "url", value: contentURL.absoluteString)]
        return components.url!
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
xcodebuild test -scheme BabyLockTests -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BabyLockTests/URLSchemeHandlerTests -quiet 2>&1 | tail -20
```

Expected: 7 tests pass.

- [ ] **Step 5: Commit**

```bash
git add BabyLock/Shared/URLSchemeHandler.swift BabyLockTests/URLSchemeHandlerTests.swift
git commit -m "feat: add URL scheme handler for babylock:// deep links"
```

---

## Task 4: App State + Content Manager

**Files:**
- Create: `BabyLock/App/AppState.swift`
- Create: `BabyLock/ContentManager/ContentManager.swift`
- Modify: `BabyLock/App/BabyLockApp.swift`

- [ ] **Step 1: Create AppState**

Create `BabyLock/App/AppState.swift`:

```swift
import SwiftUI

enum AppMode {
    case parent
    case child
}

enum ContentSource: Equatable {
    case none
    case web(URL)
    case localVideo(URL)
    case localPhoto(URL)

    var hasContent: Bool {
        self != .none
    }
}

@Observable
final class AppState {
    var mode: AppMode = .parent
    var contentSource: ContentSource = .none
    var showPasscodeSetup: Bool = false
    var showGuidedAccessTutorial: Bool = false

    let passcodeStore = PasscodeStore()

    var hasCompletedSetup: Bool {
        passcodeStore.hasPasscode
    }

    var hasSeenGuidedAccessTutorial: Bool {
        get { UserDefaults.standard.bool(forKey: "hasSeenGuidedAccessTutorial") }
        set { UserDefaults.standard.set(newValue, forKey: "hasSeenGuidedAccessTutorial") }
    }

    func lock() {
        mode = .child
    }

    func unlock() {
        mode = .parent
    }
}
```

- [ ] **Step 2: Create ContentManager**

Create `BabyLock/ContentManager/ContentManager.swift`:

```swift
import UIKit
import WebKit
import AVFoundation

final class ContentManager {
    let webView: WKWebView
    private(set) var player: AVPlayer?
    private(set) var photoImage: UIImage?

    init() {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        webView = WKWebView(frame: .zero, configuration: config)
        webView.allowsBackForwardNavigationGestures = false
    }

    func loadURL(_ url: URL) {
        player = nil
        photoImage = nil
        webView.load(URLRequest(url: url))
    }

    func loadVideo(_ url: URL) {
        photoImage = nil
        player = AVPlayer(url: url)
        player?.play()
    }

    func loadPhoto(_ image: UIImage) {
        player?.pause()
        player = nil
        photoImage = image
    }

    func clearContent() {
        player?.pause()
        player = nil
        photoImage = nil
        webView.stopLoading()
    }
}
```

- [ ] **Step 3: Update BabyLockApp with state and URL handling**

Replace `BabyLock/App/BabyLockApp.swift` with:

```swift
import SwiftUI

@main
struct BabyLockApp: App {
    @State private var appState = AppState()
    @State private var contentManager = ContentManager()

    var body: some Scene {
        WindowGroup {
            RootView(contentManager: contentManager)
                .environment(appState)
                .onOpenURL { url in
                    if let contentURL = URLSchemeHandler.parse(url) {
                        contentManager.loadURL(contentURL)
                        appState.contentSource = .web(contentURL)
                    }
                }
                .onAppear {
                    checkPendingSharedURL()
                }
        }
    }

    private func checkPendingSharedURL() {
        let defaults = UserDefaults(suiteName: "group.com.ptw1255.BabyLock")
        guard let urlString = defaults?.string(forKey: "pendingURL"),
              let url = URL(string: urlString) else { return }
        defaults?.removeObject(forKey: "pendingURL")
        contentManager.loadURL(url)
        appState.contentSource = .web(url)
    }
}
```

- [ ] **Step 4: Create stub RootView so the app compiles**

Create `BabyLock/Parent/ParentView.swift` (temporary stub — will be replaced in Task 9):

```swift
import SwiftUI

struct RootView: View {
    let contentManager: ContentManager

    var body: some View {
        Text("BabyLock")
    }
}
```

- [ ] **Step 5: Build to verify**

```bash
xcodegen generate
xcodebuild build -scheme BabyLock -destination 'platform=iOS Simulator,name=iPhone 16' -quiet
```

Expected: Build succeeds.

- [ ] **Step 6: Commit**

```bash
git add BabyLock/App/AppState.swift BabyLock/ContentManager/ContentManager.swift BabyLock/App/BabyLockApp.swift BabyLock/Parent/ParentView.swift
git commit -m "feat: add AppState, ContentManager, and URL scheme handling"
```

---

## Task 5: Passcode UI (Setup + Entry)

**Files:**
- Create: `BabyLock/Shared/PasscodeEntryView.swift`
- Create: `BabyLock/Parent/PasscodeSetupView.swift`

- [ ] **Step 1: Create PasscodeEntryView**

This is the reusable PIN entry component used for both setup and unlock.

Create `BabyLock/Shared/PasscodeEntryView.swift`:

```swift
import SwiftUI

struct PasscodeEntryView: View {
    let title: String
    let onComplete: (String) -> Bool

    @State private var digits: String = ""
    @State private var shakeWrong = false
    @FocusState private var isFocused: Bool

    private let codeLength = 4

    var body: some View {
        VStack(spacing: 32) {
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)

            HStack(spacing: 16) {
                ForEach(0..<codeLength, id: \.self) { index in
                    Circle()
                        .fill(index < digits.count ? Color.primary : Color.clear)
                        .frame(width: 20, height: 20)
                        .overlay(
                            Circle().stroke(Color.primary, lineWidth: 2)
                        )
                }
            }
            .modifier(ShakeEffect(shakes: shakeWrong ? 4 : 0))

            // Hidden text field to capture keyboard input
            TextField("", text: $digits)
                .keyboardType(.numberPad)
                .focused($isFocused)
                .frame(width: 0, height: 0)
                .opacity(0)
                .onChange(of: digits) { _, newValue in
                    // Only allow digits
                    let filtered = newValue.filter(\.isNumber)
                    if filtered != newValue {
                        digits = filtered
                    }
                    if filtered.count > codeLength {
                        digits = String(filtered.prefix(codeLength))
                    }
                    if digits.count == codeLength {
                        let accepted = onComplete(digits)
                        if !accepted {
                            withAnimation(.default) { shakeWrong = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                shakeWrong = false
                                digits = ""
                            }
                        }
                    }
                }
        }
        .onAppear { isFocused = true }
        .onTapGesture { isFocused = true }
    }
}

struct ShakeEffect: GeometryEffect {
    var shakes: Int
    var animatableData: CGFloat {
        get { CGFloat(shakes) }
        set { shakes = Int(newValue) }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        let offset = sin(animatableData * .pi * 2) * 10
        return ProjectionTransform(CGAffineTransform(translationX: offset, y: 0))
    }
}
```

- [ ] **Step 2: Create PasscodeSetupView**

Create `BabyLock/Parent/PasscodeSetupView.swift`:

```swift
import SwiftUI

struct PasscodeSetupView: View {
    @Environment(AppState.self) private var appState

    @State private var step: SetupStep = .create
    @State private var firstEntry: String = ""

    enum SetupStep {
        case create
        case confirm
    }

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            Image(systemName: "lock.shield.fill")
                .font(.system(size: 64))
                .foregroundStyle(.blue)

            switch step {
            case .create:
                PasscodeEntryView(title: "Create a Passcode") { code in
                    firstEntry = code
                    step = .confirm
                    return true
                }
            case .confirm:
                PasscodeEntryView(title: "Confirm Passcode") { code in
                    if code == firstEntry {
                        try? appState.passcodeStore.save(code)
                        return true
                    }
                    // Mismatch — restart
                    step = .create
                    firstEntry = ""
                    return false
                }
            }

            Text("You'll need this passcode to exit child mode.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()
        }
    }
}
```

- [ ] **Step 3: Build to verify**

```bash
xcodegen generate
xcodebuild build -scheme BabyLock -destination 'platform=iOS Simulator,name=iPhone 16' -quiet
```

Expected: Build succeeds.

- [ ] **Step 4: Commit**

```bash
git add BabyLock/Shared/PasscodeEntryView.swift BabyLock/Parent/PasscodeSetupView.swift
git commit -m "feat: add passcode setup and entry UI components"
```

---

## Task 6: Touch-Blocking Overlay

**Files:**
- Create: `BabyLock/ChildMode/TouchBlockingOverlay.swift`

- [ ] **Step 1: Implement TouchBlockingOverlay**

Create `BabyLock/ChildMode/TouchBlockingOverlay.swift`:

```swift
import UIKit

final class TouchBlockingOverlay: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isMultipleTouchEnabled = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // Intercept ALL touches — never pass them through
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        return self
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Swallow
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Swallow
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Swallow
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Swallow
    }
}
```

- [ ] **Step 2: Build to verify**

```bash
xcodebuild build -scheme BabyLock -destination 'platform=iOS Simulator,name=iPhone 16' -quiet
```

Expected: Build succeeds.

- [ ] **Step 3: Commit**

```bash
git add BabyLock/ChildMode/TouchBlockingOverlay.swift
git commit -m "feat: add touch-blocking overlay that swallows all touches"
```

---

## Task 7: Unlock Gesture Recognizer + Progress Ring

**Files:**
- Create: `BabyLock/ChildMode/UnlockGestureRecognizer.swift`
- Create: `BabyLockTests/UnlockGestureTests.swift`

- [ ] **Step 1: Write failing tests for unlock logic**

The gesture recognizer has complex state. We test the logic (timing, position, reset conditions) separately from UIKit gesture recognition.

Create `BabyLockTests/UnlockGestureTests.swift`:

```swift
import XCTest
@testable import BabyLock

final class UnlockGestureTests: XCTestCase {
    func testPointIsInCenterRegion() {
        let screenSize = CGSize(width: 390, height: 844)
        let center = CGPoint(x: 195, y: 422)

        XCTAssertTrue(UnlockGestureRecognizer.isInCenterRegion(center, screenSize: screenSize))
    }

    func testPointOutsideCenterRegion() {
        let screenSize = CGSize(width: 390, height: 844)
        let corner = CGPoint(x: 10, y: 10)

        XCTAssertFalse(UnlockGestureRecognizer.isInCenterRegion(corner, screenSize: screenSize))
    }

    func testPointAtEdgeOfCenterRegion() {
        let screenSize = CGSize(width: 390, height: 844)
        let screenCenter = CGPoint(x: 195, y: 422)
        // Point exactly 150pt away from center
        let edgePoint = CGPoint(x: screenCenter.x + 150, y: screenCenter.y)

        XCTAssertTrue(UnlockGestureRecognizer.isInCenterRegion(edgePoint, screenSize: screenSize))
    }

    func testPointJustOutsideCenterRegion() {
        let screenSize = CGSize(width: 390, height: 844)
        let screenCenter = CGPoint(x: 195, y: 422)
        let outsidePoint = CGPoint(x: screenCenter.x + 151, y: screenCenter.y)

        XCTAssertFalse(UnlockGestureRecognizer.isInCenterRegion(outsidePoint, screenSize: screenSize))
    }

    func testFingerMovedTooFar() {
        let start = CGPoint(x: 195, y: 422)
        let movedSlightly = CGPoint(x: 200, y: 425)
        let movedTooFar = CGPoint(x: 220, y: 422)

        XCTAssertFalse(UnlockGestureRecognizer.fingerMovedTooFar(from: start, to: movedSlightly))
        XCTAssertTrue(UnlockGestureRecognizer.fingerMovedTooFar(from: start, to: movedTooFar))
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
xcodebuild test -scheme BabyLockTests -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BabyLockTests/UnlockGestureTests -quiet 2>&1 | tail -20
```

Expected: Compilation error — `UnlockGestureRecognizer` not found.

- [ ] **Step 3: Implement UnlockGestureRecognizer**

Create `BabyLock/ChildMode/UnlockGestureRecognizer.swift`:

```swift
import UIKit

protocol UnlockGestureDelegate: AnyObject {
    func unlockGestureProgressChanged(_ progress: CGFloat)
    func unlockGestureCompleted()
}

final class UnlockGestureRecognizer: UIGestureRecognizer {
    weak var unlockDelegate: UnlockGestureDelegate?

    private static let holdDuration: TimeInterval = 5.0
    private static let centerRadius: CGFloat = 150.0
    private static let maxDrift: CGFloat = 20.0

    private var holdTimer: Timer?
    private var startTime: Date?
    private var initialPoint: CGPoint = .zero
    private var progressTimer: CADisplayLink?

    // MARK: - Testable static helpers

    static func isInCenterRegion(_ point: CGPoint, screenSize: CGSize) -> Bool {
        let center = CGPoint(x: screenSize.width / 2, y: screenSize.height / 2)
        let dx = point.x - center.x
        let dy = point.y - center.y
        return (dx * dx + dy * dy) <= (centerRadius * centerRadius)
    }

    static func fingerMovedTooFar(from start: CGPoint, to current: CGPoint) -> Bool {
        let dx = current.x - start.x
        let dy = current.y - start.y
        return (dx * dx + dy * dy) > (maxDrift * maxDrift)
    }

    // MARK: - Touch handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        // If more than one touch total, reset
        if let allTouches = event.allTouches, allTouches.count > 1 {
            resetHold()
            return
        }

        guard let touch = touches.first else {
            resetHold()
            return
        }

        let point = touch.location(in: view)
        guard let viewSize = view?.bounds.size,
              Self.isInCenterRegion(point, screenSize: viewSize) else {
            resetHold()
            return
        }

        initialPoint = point
        startTime = Date()
        startProgressReporting()

        holdTimer = Timer.scheduledTimer(withTimeInterval: Self.holdDuration, repeats: false) { [weak self] _ in
            self?.unlockDelegate?.unlockGestureProgressChanged(1.0)
            self?.unlockDelegate?.unlockGestureCompleted()
            self?.resetHold()
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        guard let touch = touches.first else { return }
        let current = touch.location(in: view)

        if Self.fingerMovedTooFar(from: initialPoint, to: current) {
            resetHold()
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        resetHold()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        resetHold()
    }

    private func startProgressReporting() {
        progressTimer?.invalidate()
        progressTimer = CADisplayLink(target: self, selector: #selector(reportProgress))
        progressTimer?.add(to: .main, forMode: .common)
    }

    @objc private func reportProgress() {
        guard let startTime else { return }
        let elapsed = Date().timeIntervalSince(startTime)
        let progress = min(elapsed / Self.holdDuration, 1.0)
        unlockDelegate?.unlockGestureProgressChanged(CGFloat(progress))
    }

    private func resetHold() {
        holdTimer?.invalidate()
        holdTimer = nil
        startTime = nil
        progressTimer?.invalidate()
        progressTimer = nil
        unlockDelegate?.unlockGestureProgressChanged(0)
    }
}
```

**Note:** The `touchesBegan` implementation above already handles multi-touch reset via `event.allTouches?.count > 1`.

- [ ] **Step 4: Run tests to verify they pass**

```bash
xcodebuild test -scheme BabyLockTests -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BabyLockTests/UnlockGestureTests -quiet 2>&1 | tail -20
```

Expected: 5 tests pass.

- [ ] **Step 5: Commit**

```bash
git add BabyLock/ChildMode/UnlockGestureRecognizer.swift BabyLockTests/UnlockGestureTests.swift
git commit -m "feat: add unlock gesture recognizer with 5-sec hold detection"
```

---

## Task 8: Child Mode Controller

**Files:**
- Create: `BabyLock/ChildMode/ChildModeController.swift`

- [ ] **Step 1: Implement ChildModeController**

Create `BabyLock/ChildMode/ChildModeController.swift`:

```swift
import UIKit
import WebKit
import AVFoundation
import AVKit
import SwiftUI

final class ChildModeController: UIViewController, UnlockGestureDelegate {
    private let contentManager: ContentManager
    private let contentSource: ContentSource
    private let passcodeStore: PasscodeStore
    private let onUnlock: () -> Void

    private let overlay = TouchBlockingOverlay()
    private let unlockGesture = UnlockGestureRecognizer(target: nil, action: nil)
    private let progressRing = ProgressRingLayer()

    private var playerLayer: AVPlayerLayer?

    init(contentManager: ContentManager, contentSource: ContentSource,
         passcodeStore: PasscodeStore, onUnlock: @escaping () -> Void) {
        self.contentManager = contentManager
        self.contentSource = contentSource
        self.passcodeStore = passcodeStore
        self.onUnlock = onUnlock
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - System overrides for child mode

    override var prefersStatusBarHidden: Bool { true }
    override var prefersHomeIndicatorAutoHidden: Bool { true }
    override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge { .all }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        setupContentView()
        setupOverlay()
        setupUnlockGesture()
        setupProgressRing()

        UIApplication.shared.isIdleTimerDisabled = true
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        UIApplication.shared.isIdleTimerDisabled = false
    }

    // MARK: - Content setup

    private func setupContentView() {
        switch contentSource {
        case .web:
            let webView = contentManager.webView
            webView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(webView)
            NSLayoutConstraint.activate([
                webView.topAnchor.constraint(equalTo: view.topAnchor),
                webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                webView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            ])

        case .localVideo:
            guard let player = contentManager.player else { return }
            let layer = AVPlayerLayer(player: player)
            layer.videoGravity = .resizeAspect
            layer.frame = view.bounds
            view.layer.addSublayer(layer)
            playerLayer = layer

        case .localPhoto:
            guard let image = contentManager.photoImage else { return }
            let imageView = UIImageView(image: image)
            imageView.contentMode = .scaleAspectFit
            imageView.backgroundColor = .black
            imageView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(imageView)
            NSLayoutConstraint.activate([
                imageView.topAnchor.constraint(equalTo: view.topAnchor),
                imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            ])

        case .none:
            break
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer?.frame = view.bounds
        overlay.frame = view.bounds
        progressRing.position = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
    }

    // MARK: - Overlay + Gesture

    private func setupOverlay() {
        overlay.frame = view.bounds
        overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(overlay)
    }

    private func setupUnlockGesture() {
        unlockGesture.unlockDelegate = self
        overlay.addGestureRecognizer(unlockGesture)
    }

    private func setupProgressRing() {
        progressRing.bounds = CGRect(x: 0, y: 0, width: 80, height: 80)
        progressRing.position = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
        progressRing.opacity = 0
        overlay.layer.addSublayer(progressRing)
    }

    // MARK: - UnlockGestureDelegate

    func unlockGestureProgressChanged(_ progress: CGFloat) {
        if progress > 0 {
            progressRing.opacity = Float(min(progress * 2, 0.6))
            progressRing.strokeEnd = progress
        } else {
            progressRing.opacity = 0
            progressRing.strokeEnd = 0
        }
    }

    func unlockGestureCompleted() {
        progressRing.opacity = 0
        showPasscodeEntry()
    }

    // MARK: - Passcode

    private func showPasscodeEntry() {
        let passcodeVC = UIHostingController(rootView:
            PasscodeEntryView(title: "Enter Passcode to Unlock") { [weak self] code in
                guard let self else { return false }
                if self.passcodeStore.verify(code) {
                    self.dismiss(animated: false) {
                        self.onUnlock()
                    }
                    return true
                }
                return false
            }
            .background(Color.black.opacity(0.9))
        )
        passcodeVC.modalPresentationStyle = .overFullScreen
        passcodeVC.view.backgroundColor = UIColor.black.withAlphaComponent(0.9)
        present(passcodeVC, animated: true)
    }
}

// MARK: - Progress Ring CALayer

final class ProgressRingLayer: CAShapeLayer {
    override init() {
        super.init()
        setup()
    }

    override init(layer: Any) {
        super.init(layer: layer)
    }

    required init?(coder: NSCoder) { fatalError() }

    var strokeEnd: CGFloat = 0 {
        didSet {
            let circle = UIBezierPath(
                arcCenter: CGPoint(x: bounds.midX, y: bounds.midY),
                radius: 30,
                startAngle: -.pi / 2,
                endAngle: -.pi / 2 + (.pi * 2 * strokeEnd),
                clockwise: true
            )
            path = circle.cgPath
        }
    }

    private func setup() {
        fillColor = nil
        strokeColor = UIColor.white.withAlphaComponent(0.5).cgColor
        lineWidth = 3
        lineCap = .round
    }
}
```

- [ ] **Step 2: Build to verify**

```bash
xcodegen generate
xcodebuild build -scheme BabyLock -destination 'platform=iOS Simulator,name=iPhone 16' -quiet
```

Expected: Build succeeds.

- [ ] **Step 3: Commit**

```bash
git add BabyLock/ChildMode/ChildModeController.swift
git commit -m "feat: add child mode controller with fullscreen lock and gesture deferral"
```

---

## Task 9: WKWebView Browser

**Files:**
- Create: `BabyLock/Parent/BrowserView.swift`
- Create: `BabyLock/Parent/BrowserToolbar.swift`

- [ ] **Step 1: Create BrowserView**

Create `BabyLock/Parent/BrowserView.swift`:

```swift
import SwiftUI
import WebKit

struct BrowserView: UIViewRepresentable {
    let webView: WKWebView
    let onURLChange: (URL?) -> Void

    func makeUIView(context: Context) -> WKWebView {
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onURLChange: onURLChange)
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        let onURLChange: (URL?) -> Void

        init(onURLChange: @escaping (URL?) -> Void) {
            self.onURLChange = onURLChange
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                      decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.allow)
                return
            }

            // Block non-http(s) schemes to prevent opening other apps
            if let scheme = url.scheme?.lowercased(),
               scheme != "https" && scheme != "http" && scheme != "about" && scheme != "blob" {
                decisionHandler(.cancel)
                return
            }

            // Block popups / new window requests
            if navigationAction.targetFrame == nil {
                webView.load(navigationAction.request)
                decisionHandler(.cancel)
                return
            }

            decisionHandler(.allow)
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            onURLChange(webView.url)
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            onURLChange(webView.url)
        }
    }
}
```

- [ ] **Step 2: Create BrowserToolbar**

Create `BabyLock/Parent/BrowserToolbar.swift`:

```swift
import SwiftUI
import WebKit

struct BrowserToolbar: View {
    let webView: WKWebView
    @Binding var urlText: String
    let onGo: () -> Void
    let onMediaPicker: () -> Void
    let onSettings: () -> Void
    let onLock: () -> Void
    let canLock: Bool

    var body: some View {
        VStack(spacing: 8) {
            // Address bar
            HStack(spacing: 8) {
                Button(action: { webView.goBack() }) {
                    Image(systemName: "chevron.left")
                }
                .disabled(!webView.canGoBack)

                Button(action: { webView.goForward() }) {
                    Image(systemName: "chevron.right")
                }
                .disabled(!webView.canGoForward)

                Button(action: { webView.reload() }) {
                    Image(systemName: "arrow.clockwise")
                }

                TextField("Search or enter URL", text: $urlText)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .keyboardType(.URL)
                    .submitLabel(.go)
                    .onSubmit(onGo)
            }
            .padding(.horizontal)

            // Action bar
            HStack(spacing: 20) {
                Button(action: onMediaPicker) {
                    Label("Photos", systemImage: "photo.on.rectangle")
                }

                Spacer()

                Button(action: onLock) {
                    Label("Lock", systemImage: "lock.fill")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(canLock ? Color.blue : Color.gray)
                        .clipShape(Capsule())
                }
                .disabled(!canLock)

                Spacer()

                Button(action: onSettings) {
                    Label("Settings", systemImage: "gear")
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .background(.bar)
    }
}
```

- [ ] **Step 3: Build to verify**

```bash
xcodegen generate
xcodebuild build -scheme BabyLock -destination 'platform=iOS Simulator,name=iPhone 16' -quiet
```

Expected: Build succeeds.

- [ ] **Step 4: Commit**

```bash
git add BabyLock/Parent/BrowserView.swift BabyLock/Parent/BrowserToolbar.swift
git commit -m "feat: add WKWebView browser with navigation controls and toolbar"
```

---

## Task 10: Local Media Picker + Player

**Files:**
- Create: `BabyLock/Parent/MediaPlayerView.swift`

- [ ] **Step 1: Create MediaPlayerView**

Create `BabyLock/Parent/MediaPlayerView.swift`:

```swift
import SwiftUI
import PhotosUI
import AVKit

struct MediaPickerButton: View {
    let contentManager: ContentManager
    let onSelected: (ContentSource) -> Void

    @State private var selectedItem: PhotosPickerItem?

    var body: some View {
        PhotosPicker(selection: $selectedItem, matching: .any(of: [.videos, .images])) {
            Label("Choose from Library", systemImage: "photo.on.rectangle")
        }
        .onChange(of: selectedItem) { _, newItem in
            guard let newItem else { return }
            Task {
                await loadItem(newItem)
            }
        }
    }

    private func loadItem(_ item: PhotosPickerItem) async {
        // Try video first
        if let videoData = try? await item.loadTransferable(type: VideoTransferable.self) {
            await MainActor.run {
                contentManager.loadVideo(videoData.url)
                onSelected(.localVideo(videoData.url))
            }
            return
        }

        // Try image
        if let imageData = try? await item.loadTransferable(type: Data.self),
           let image = UIImage(data: imageData) {
            await MainActor.run {
                contentManager.loadPhoto(image)
                onSelected(.localPhoto(URL(string: "local://photo")!))
            }
        }
    }
}

struct VideoTransferable: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { video in
            SentTransferredFile(video.url)
        } importing: { received in
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("mov")
            try FileManager.default.copyItem(at: received.file, to: tempURL)
            return Self(url: tempURL)
        }
    }
}

struct MediaPlayerView: View {
    let contentManager: ContentManager
    let contentSource: ContentSource

    var body: some View {
        switch contentSource {
        case .localVideo:
            if let player = contentManager.player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
            }
        case .localPhoto:
            if let image = contentManager.photoImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .background(Color.black)
            }
        default:
            EmptyView()
        }
    }
}
```

- [ ] **Step 2: Build to verify**

```bash
xcodegen generate
xcodebuild build -scheme BabyLock -destination 'platform=iOS Simulator,name=iPhone 16' -quiet
```

Expected: Build succeeds.

- [ ] **Step 3: Commit**

```bash
git add BabyLock/Parent/MediaPlayerView.swift
git commit -m "feat: add media picker and player for local photos and videos"
```

---

## Task 11: Parent View + Root View + Lock Flow

**Files:**
- Modify: `BabyLock/Parent/ParentView.swift` (replace stub from Task 4)

- [ ] **Step 1: Implement the full ParentView and RootView**

Replace `BabyLock/Parent/ParentView.swift` with:

```swift
import SwiftUI

struct RootView: View {
    let contentManager: ContentManager
    @Environment(AppState.self) private var appState

    var body: some View {
        Group {
            if !appState.hasCompletedSetup {
                PasscodeSetupView()
            } else {
                ParentView(contentManager: contentManager)
            }
        }
    }
}

struct ParentView: View {
    let contentManager: ContentManager
    @Environment(AppState.self) private var appState

    @State private var urlText = ""
    @State private var showSettings = false
    @State private var showMediaPicker = false
    @State private var isChildModePresented = false

    var body: some View {
        VStack(spacing: 0) {
            // Content area
            ZStack {
                switch appState.contentSource {
                case .none, .web:
                    BrowserView(webView: contentManager.webView) { newURL in
                        if let newURL {
                            urlText = newURL.absoluteString
                        }
                    }
                case .localVideo, .localPhoto:
                    MediaPlayerView(contentManager: contentManager, contentSource: appState.contentSource)
                }
            }

            // Toolbar
            BrowserToolbar(
                webView: contentManager.webView,
                urlText: $urlText,
                onGo: navigateToURL,
                onMediaPicker: { showMediaPicker = true },
                onSettings: { showSettings = true },
                onLock: activateLock,
                canLock: appState.contentSource.hasContent
            )
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showMediaPicker) {
            MediaPickerSheet(contentManager: contentManager) { source in
                appState.contentSource = source
                showMediaPicker = false
            }
        }
        .onChange(of: isChildModePresented) { _, newValue in
            if !newValue {
                appState.unlock()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .presentChildMode)) { _ in
            presentChildMode()
        }
    }

    private func navigateToURL() {
        var text = urlText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !text.contains("://") {
            if text.contains(".") && !text.contains(" ") {
                text = "https://\(text)"
            } else {
                text = "https://www.google.com/search?q=\(text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? text)"
            }
        }
        guard let url = URL(string: text) else { return }
        contentManager.loadURL(url)
        appState.contentSource = .web(url)
    }

    private func activateLock() {
        appState.lock()
        presentChildMode()
    }

    private func presentChildMode() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else { return }

        // Walk to the topmost presented VC
        var topVC = rootVC
        while let presented = topVC.presentedViewController {
            topVC = presented
        }

        let childModeVC = ChildModeController(
            contentManager: contentManager,
            contentSource: appState.contentSource,
            passcodeStore: appState.passcodeStore,
            onUnlock: { [weak topVC] in
                topVC?.dismiss(animated: false)
                appState.unlock()
                checkGuidedAccessTutorial()
            }
        )
        topVC.present(childModeVC, animated: false)
    }

    private func checkGuidedAccessTutorial() {
        if !appState.hasSeenGuidedAccessTutorial && !UIAccessibility.isGuidedAccessEnabled {
            appState.hasSeenGuidedAccessTutorial = true
            appState.showGuidedAccessTutorial = true
        }
    }
}

struct MediaPickerSheet: View {
    let contentManager: ContentManager
    let onSelected: (ContentSource) -> Void

    var body: some View {
        NavigationStack {
            VStack {
                MediaPickerButton(contentManager: contentManager, onSelected: onSelected)
                    .padding()
                Spacer()
            }
            .navigationTitle("Choose Media")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

extension Notification.Name {
    static let presentChildMode = Notification.Name("presentChildMode")
}
```

- [ ] **Step 2: Create a stub SettingsView so it compiles**

Create `BabyLock/Parent/SettingsView.swift` (will be completed in Task 13):

```swift
import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Text("Settings coming soon")
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
```

- [ ] **Step 3: Build to verify**

```bash
xcodegen generate
xcodebuild build -scheme BabyLock -destination 'platform=iOS Simulator,name=iPhone 16' -quiet
```

Expected: Build succeeds.

- [ ] **Step 4: Run all tests**

```bash
xcodebuild test -scheme BabyLockTests -destination 'platform=iOS Simulator,name=iPhone 16' -quiet 2>&1 | tail -20
```

Expected: All existing tests pass (21 tests).

- [ ] **Step 5: Commit**

```bash
git add BabyLock/Parent/ParentView.swift BabyLock/Parent/SettingsView.swift
git commit -m "feat: add parent view with browser, media picker, and lock flow"
```

---

## Task 12: Share Extension

**Files:**
- Modify: `BabyLockShareExtension/ShareViewController.swift`

- [ ] **Step 1: Implement ShareViewController**

Replace `BabyLockShareExtension/ShareViewController.swift` with:

```swift
import UIKit
import UniformTypeIdentifiers

class ShareViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        extractURL()
    }

    private func extractURL() {
        guard let items = extensionContext?.inputItems as? [NSExtensionItem] else {
            close()
            return
        }

        for item in items {
            guard let attachments = item.attachments else { continue }
            for provider in attachments {
                if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                    provider.loadItem(forTypeIdentifier: UTType.url.identifier) { [weak self] item, _ in
                        DispatchQueue.main.async {
                            if let url = item as? URL {
                                self?.handleURL(url)
                            } else if let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) {
                                self?.handleURL(url)
                            } else {
                                self?.close()
                            }
                        }
                    }
                    return
                }
            }
        }
        close()
    }

    private func handleURL(_ url: URL) {
        // Save to App Group shared container
        let defaults = UserDefaults(suiteName: "group.com.ptw1255.BabyLock")
        defaults?.set(url.absoluteString, forKey: "pendingURL")

        // Attempt to open the main app via URL scheme
        let babylockURL = URL(string: "babylock://open?url=\(url.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")")!

        // Use responder chain to open URL (works in practice on iOS)
        var responder: UIResponder? = self
        while let nextResponder = responder?.next {
            if let application = nextResponder as? UIApplication {
                application.open(babylockURL)
                break
            }
            // Check if the responder responds to openURL:
            let selector = NSSelectorFromString("openURL:")
            if nextResponder.responds(to: selector) {
                nextResponder.perform(selector, with: babylockURL)
                break
            }
            responder = nextResponder
        }

        close()
    }

    private func close() {
        extensionContext?.completeRequest(returningItems: nil)
    }
}
```

- [ ] **Step 2: Build to verify**

```bash
xcodegen generate
xcodebuild build -scheme BabyLock -destination 'platform=iOS Simulator,name=iPhone 16' -quiet
```

Expected: Build succeeds.

- [ ] **Step 3: Commit**

```bash
git add BabyLockShareExtension/ShareViewController.swift
git commit -m "feat: add share extension to receive URLs from Safari"
```

---

## Task 13: Settings + Guided Access Tutorial

**Files:**
- Modify: `BabyLock/Parent/SettingsView.swift`

- [ ] **Step 1: Implement full SettingsView with Guided Access tutorial**

Replace `BabyLock/Parent/SettingsView.swift` with:

```swift
import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var showPasscodeChange = false
    @State private var showGuidedAccessInfo = false

    var body: some View {
        NavigationStack {
            List {
                Section("Security") {
                    Button("Change Passcode") {
                        showPasscodeChange = true
                    }
                }

                Section("Guided Access") {
                    HStack {
                        Text("Status")
                        Spacer()
                        Text(UIAccessibility.isGuidedAccessEnabled ? "Active" : "Not Active")
                            .foregroundStyle(UIAccessibility.isGuidedAccessEnabled ? .green : .secondary)
                    }

                    Button("How to Enable Guided Access") {
                        showGuidedAccessInfo = true
                    }
                }

                Section {
                    Text("BabyLock blocks all screen touches while your child watches content. For complete protection, enable Guided Access to also prevent exiting the app.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showPasscodeChange) {
                ChangePasscodeView()
            }
            .sheet(isPresented: $showGuidedAccessInfo) {
                GuidedAccessTutorialView()
            }
        }
    }
}

struct ChangePasscodeView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var step: ChangeStep = .verify

    enum ChangeStep {
        case verify
        case create
        case confirm
    }

    @State private var newPasscode = ""

    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                switch step {
                case .verify:
                    PasscodeEntryView(title: "Enter Current Passcode") { code in
                        if appState.passcodeStore.verify(code) {
                            step = .create
                            return true
                        }
                        return false
                    }
                case .create:
                    PasscodeEntryView(title: "Enter New Passcode") { code in
                        newPasscode = code
                        step = .confirm
                        return true
                    }
                case .confirm:
                    PasscodeEntryView(title: "Confirm New Passcode") { code in
                        if code == newPasscode {
                            try? appState.passcodeStore.save(code)
                            dismiss()
                            return true
                        }
                        step = .create
                        newPasscode = ""
                        return false
                    }
                }
                Spacer()
            }
            .navigationTitle("Change Passcode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

struct GuidedAccessTutorialView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Guided Access prevents your child from leaving BabyLock by disabling the home gesture, side button, and notifications.")
                        .font(.body)

                    VStack(alignment: .leading, spacing: 16) {
                        TutorialStep(number: 1, text: "Open **Settings** > **Accessibility** > **Guided Access**")
                        TutorialStep(number: 2, text: "Turn **Guided Access** on")
                        TutorialStep(number: 3, text: "Set a Guided Access passcode (can be different from your BabyLock passcode)")
                        TutorialStep(number: 4, text: "Open BabyLock, load your content, and tap **Lock**")
                        TutorialStep(number: 5, text: "**Triple-click the side button** to start Guided Access")
                        TutorialStep(number: 6, text: "To exit: **triple-click the side button** and enter your Guided Access passcode")
                    }

                    Text("With both BabyLock and Guided Access active, the device is fully locked. The only way out is your passcode or a device restart.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
            .navigationTitle("Guided Access Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct TutorialStep: View {
    let number: Int
    let text: LocalizedStringKey

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(Color.blue)
                .clipShape(Circle())

            Text(text)
                .font(.body)
        }
    }
}
```

- [ ] **Step 2: Wire up Guided Access tutorial prompt in BabyLockApp**

Modify `BabyLock/App/BabyLockApp.swift` — add an alert after the first unlock prompting the user:

```swift
import SwiftUI

@main
struct BabyLockApp: App {
    @State private var appState = AppState()
    @State private var contentManager = ContentManager()

    var body: some Scene {
        WindowGroup {
            RootView(contentManager: contentManager)
                .environment(appState)
                .onOpenURL { url in
                    if let contentURL = URLSchemeHandler.parse(url) {
                        contentManager.loadURL(contentURL)
                        appState.contentSource = .web(contentURL)
                    }
                }
                .onAppear {
                    checkPendingSharedURL()
                }
                .sheet(isPresented: Binding(
                    get: { appState.showGuidedAccessTutorial },
                    set: { appState.showGuidedAccessTutorial = $0 }
                )) {
                    GuidedAccessTutorialView()
                }
        }
    }

    private func checkPendingSharedURL() {
        let defaults = UserDefaults(suiteName: "group.com.ptw1255.BabyLock")
        guard let urlString = defaults?.string(forKey: "pendingURL"),
              let url = URL(string: urlString) else { return }
        defaults?.removeObject(forKey: "pendingURL")
        contentManager.loadURL(url)
        appState.contentSource = .web(url)
    }
}
```

- [ ] **Step 3: Build to verify**

```bash
xcodegen generate
xcodebuild build -scheme BabyLock -destination 'platform=iOS Simulator,name=iPhone 16' -quiet
```

Expected: Build succeeds.

- [ ] **Step 4: Run all tests**

```bash
xcodebuild test -scheme BabyLockTests -destination 'platform=iOS Simulator,name=iPhone 16' -quiet 2>&1 | tail -20
```

Expected: All 21 tests pass.

- [ ] **Step 5: Commit**

```bash
git add BabyLock/Parent/SettingsView.swift BabyLock/App/BabyLockApp.swift
git commit -m "feat: add settings, passcode change, and Guided Access tutorial"
```

---

## Post-Implementation Checklist

After all tasks are complete, verify the full app flow:

- [ ] **Clean build from scratch**
```bash
xcodegen generate
xcodebuild clean build -scheme BabyLock -destination 'platform=iOS Simulator,name=iPhone 16' -quiet
```

- [ ] **All tests pass**
```bash
xcodebuild test -scheme BabyLockTests -destination 'platform=iOS Simulator,name=iPhone 16' -quiet
```

- [ ] **Run on simulator and verify:**
1. First launch shows passcode setup
2. After setting passcode, main browser view appears
3. Type a URL → page loads
4. Tap Lock → fullscreen child mode, no controls visible
5. Touch the screen → nothing happens
6. 5-second hold center → progress ring → passcode prompt
7. Wrong passcode → back to child mode
8. Correct passcode → back to parent mode
9. Settings → change passcode works
10. Settings → Guided Access tutorial displays correctly

- [ ] **Final commit and push**
```bash
git push origin main
```
