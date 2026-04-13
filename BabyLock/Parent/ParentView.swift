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

    var body: some View {
        VStack(spacing: 0) {
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

        var topVC = rootVC
        while let presented = topVC.presentedViewController {
            topVC = presented
        }

        let childModeVC = ChildModeController(
            contentManager: contentManager,
            contentSource: appState.contentSource,
            passcodeStore: appState.passcodeStore,
            onUnlock: {
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
