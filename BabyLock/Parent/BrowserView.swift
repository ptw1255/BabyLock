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
            if let scheme = url.scheme?.lowercased(),
               scheme != "https" && scheme != "http" && scheme != "about" && scheme != "blob" {
                decisionHandler(.cancel)
                return
            }
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
