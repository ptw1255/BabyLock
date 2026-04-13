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
