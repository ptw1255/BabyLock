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
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)
                    .submitLabel(.go)
                    .onSubmit(onGo)
            }
            .padding(.horizontal)

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
