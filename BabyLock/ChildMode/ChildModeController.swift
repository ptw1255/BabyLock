import UIKit
import WebKit
import AVFoundation
import AVKit
import SwiftUI

final class ChildModeController: UIViewController, UnlockGestureDelegate {
    private let contentManager: ContentManager
    private let contentSource: ContentSource
    private let passcodeStore: PasscodeStore
    private let onUnlock: () -> Void

    private let overlay = TouchBlockingOverlay()
    private let unlockGesture = UnlockGestureRecognizer(target: nil, action: nil)
    private let progressRing = ProgressRingLayer()

    private var playerLayer: AVPlayerLayer?

    init(contentManager: ContentManager, contentSource: ContentSource,
         passcodeStore: PasscodeStore, onUnlock: @escaping () -> Void) {
        self.contentManager = contentManager
        self.contentSource = contentSource
        self.passcodeStore = passcodeStore
        self.onUnlock = onUnlock
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }

    required init?(coder: NSCoder) { fatalError() }

    deinit {
        UIApplication.shared.isIdleTimerDisabled = false
    }

    override var prefersStatusBarHidden: Bool { true }
    override var prefersHomeIndicatorAutoHidden: Bool { true }
    override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge { .all }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupContentView()
        setupOverlay()
        setupUnlockGesture()
        setupProgressRing()
        UIApplication.shared.isIdleTimerDisabled = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        contentManager.webView.removeFromSuperview()
        UIApplication.shared.isIdleTimerDisabled = false
    }

    private func setupContentView() {
        switch contentSource {
        case .web:
            let webView = contentManager.webView
            webView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(webView)
            NSLayoutConstraint.activate([
                webView.topAnchor.constraint(equalTo: view.topAnchor),
                webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                webView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            ])
        case .localVideo:
            guard let player = contentManager.player else { return }
            let layer = AVPlayerLayer(player: player)
            layer.videoGravity = .resizeAspect
            layer.frame = view.bounds
            view.layer.addSublayer(layer)
            playerLayer = layer
        case .localPhoto:
            guard let image = contentManager.photoImage else { return }
            let imageView = UIImageView(image: image)
            imageView.contentMode = .scaleAspectFit
            imageView.backgroundColor = .black
            imageView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(imageView)
            NSLayoutConstraint.activate([
                imageView.topAnchor.constraint(equalTo: view.topAnchor),
                imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            ])
        case .none:
            break
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer?.frame = view.bounds
        overlay.frame = view.bounds
        progressRing.position = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
    }

    private func setupOverlay() {
        overlay.frame = view.bounds
        overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(overlay)
    }

    private func setupUnlockGesture() {
        unlockGesture.unlockDelegate = self
        overlay.addGestureRecognizer(unlockGesture)
    }

    private func setupProgressRing() {
        progressRing.bounds = CGRect(x: 0, y: 0, width: 80, height: 80)
        progressRing.position = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
        progressRing.opacity = 0
        overlay.layer.addSublayer(progressRing)
    }

    func unlockGestureProgressChanged(_ progress: CGFloat) {
        if progress > 0 {
            progressRing.opacity = Float(min(progress * 2, 0.6))
            progressRing.progress = progress
        } else {
            progressRing.opacity = 0
            progressRing.progress = 0
        }
    }

    func unlockGestureCompleted() {
        progressRing.opacity = 0
        showPasscodeEntry()
    }

    private func showPasscodeEntry() {
        let passcodeVC = UIHostingController(rootView:
            PasscodeEntryView(title: "Enter Passcode to Unlock") { [weak self] code in
                guard let self else { return false }
                if self.passcodeStore.verify(code) {
                    // Dismiss passcode VC first, then dismiss ChildModeController
                    self.dismiss(animated: false) {
                        self.presentingViewController?.dismiss(animated: false) {
                            self.onUnlock()
                        }
                    }
                    return true
                }
                return false
            }
            .background(Color.black.opacity(0.9))
        )
        passcodeVC.modalPresentationStyle = .overFullScreen
        passcodeVC.view.backgroundColor = UIColor.black.withAlphaComponent(0.9)
        present(passcodeVC, animated: true)
    }
}

final class ProgressRingLayer: CAShapeLayer {
    override init() {
        super.init()
        setup()
    }

    override init(layer: Any) {
        super.init(layer: layer)
    }

    required init?(coder: NSCoder) { fatalError() }

    var progress: CGFloat = 0 {
        didSet {
            let circle = UIBezierPath(
                arcCenter: CGPoint(x: bounds.midX, y: bounds.midY),
                radius: 30,
                startAngle: -.pi / 2,
                endAngle: -.pi / 2 + (.pi * 2 * progress),
                clockwise: true
            )
            path = circle.cgPath
            strokeEnd = 1.0
        }
    }

    private func setup() {
        fillColor = nil
        strokeColor = UIColor.white.withAlphaComponent(0.5).cgColor
        lineWidth = 3
        lineCap = .round
    }
}
