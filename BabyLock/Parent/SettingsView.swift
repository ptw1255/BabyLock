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
