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
        let encoded = url.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let babylockURL = URL(string: "babylock://open?url=\(encoded)")!

        // Use responder chain to open URL
        var responder: UIResponder? = self
        while let nextResponder = responder?.next {
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
