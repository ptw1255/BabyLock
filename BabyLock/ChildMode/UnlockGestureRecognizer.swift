import UIKit

protocol UnlockGestureDelegate: AnyObject {
    func unlockGestureProgressChanged(_ progress: CGFloat)
    func unlockGestureCompleted()
}

final class UnlockGestureRecognizer: UIGestureRecognizer {
    weak var unlockDelegate: UnlockGestureDelegate?

    private static let holdDuration: TimeInterval = 5.0
    private static let centerRadius: CGFloat = 150.0
    private static let maxDrift: CGFloat = 20.0

    private var holdTimer: Timer?
    private var startTime: Date?
    private var initialPoint: CGPoint = .zero
    private var progressTimer: CADisplayLink?

    static func isInCenterRegion(_ point: CGPoint, screenSize: CGSize) -> Bool {
        let center = CGPoint(x: screenSize.width / 2, y: screenSize.height / 2)
        let dx = point.x - center.x
        let dy = point.y - center.y
        return (dx * dx + dy * dy) <= (centerRadius * centerRadius)
    }

    static func fingerMovedTooFar(from start: CGPoint, to current: CGPoint) -> Bool {
        let dx = current.x - start.x
        let dy = current.y - start.y
        return (dx * dx + dy * dy) > (maxDrift * maxDrift)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        if let allTouches = event.allTouches, allTouches.count > 1 {
            resetHold()
            return
        }
        guard let touch = touches.first else {
            resetHold()
            return
        }
        let point = touch.location(in: view)
        guard let viewSize = view?.bounds.size,
              Self.isInCenterRegion(point, screenSize: viewSize) else {
            resetHold()
            return
        }
        initialPoint = point
        startTime = Date()
        startProgressReporting()
        holdTimer = Timer.scheduledTimer(withTimeInterval: Self.holdDuration, repeats: false) { [weak self] _ in
            self?.unlockDelegate?.unlockGestureProgressChanged(1.0)
            self?.unlockDelegate?.unlockGestureCompleted()
            self?.resetHold()
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        guard let touch = touches.first else { return }
        let current = touch.location(in: view)
        if Self.fingerMovedTooFar(from: initialPoint, to: current) {
            resetHold()
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        resetHold()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        resetHold()
    }

    private var displayLinkProxy: DisplayLinkProxy?

    private func startProgressReporting() {
        progressTimer?.invalidate()
        let proxy = DisplayLinkProxy()
        proxy.target = self
        displayLinkProxy = proxy
        progressTimer = CADisplayLink(target: proxy, selector: #selector(DisplayLinkProxy.tick))
        progressTimer?.add(to: .main, forMode: .common)
    }

    @objc fileprivate func reportProgress() {
        guard let startTime else { return }
        let elapsed = Date().timeIntervalSince(startTime)
        let progress = min(elapsed / Self.holdDuration, 1.0)
        unlockDelegate?.unlockGestureProgressChanged(CGFloat(progress))
    }

    private func resetHold() {
        holdTimer?.invalidate()
        holdTimer = nil
        startTime = nil
        progressTimer?.invalidate()
        progressTimer = nil
        displayLinkProxy = nil
        unlockDelegate?.unlockGestureProgressChanged(0)
    }
}

private class DisplayLinkProxy {
    weak var target: UnlockGestureRecognizer?
    @objc func tick() { target?.reportProgress() }
}
