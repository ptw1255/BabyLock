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
