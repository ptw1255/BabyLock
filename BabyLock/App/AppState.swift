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

    func lock() { mode = .child }
    func unlock() { mode = .parent }
}
