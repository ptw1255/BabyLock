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
