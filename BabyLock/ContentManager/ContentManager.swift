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
