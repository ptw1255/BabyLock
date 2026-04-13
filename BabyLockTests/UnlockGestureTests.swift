import XCTest
@testable import BabyLock

final class UnlockGestureTests: XCTestCase {
    func testPointIsInCenterRegion() {
        let screenSize = CGSize(width: 390, height: 844)
        let center = CGPoint(x: 195, y: 422)
        XCTAssertTrue(UnlockGestureRecognizer.isInCenterRegion(center, screenSize: screenSize))
    }

    func testPointOutsideCenterRegion() {
        let screenSize = CGSize(width: 390, height: 844)
        let corner = CGPoint(x: 10, y: 10)
        XCTAssertFalse(UnlockGestureRecognizer.isInCenterRegion(corner, screenSize: screenSize))
    }

    func testPointAtEdgeOfCenterRegion() {
        let screenSize = CGSize(width: 390, height: 844)
        let screenCenter = CGPoint(x: 195, y: 422)
        let edgePoint = CGPoint(x: screenCenter.x + 150, y: screenCenter.y)
        XCTAssertTrue(UnlockGestureRecognizer.isInCenterRegion(edgePoint, screenSize: screenSize))
    }

    func testPointJustOutsideCenterRegion() {
        let screenSize = CGSize(width: 390, height: 844)
        let screenCenter = CGPoint(x: 195, y: 422)
        let outsidePoint = CGPoint(x: screenCenter.x + 151, y: screenCenter.y)
        XCTAssertFalse(UnlockGestureRecognizer.isInCenterRegion(outsidePoint, screenSize: screenSize))
    }

    func testFingerMovedTooFar() {
        let start = CGPoint(x: 195, y: 422)
        let movedSlightly = CGPoint(x: 200, y: 425)
        let movedTooFar = CGPoint(x: 220, y: 422)
        XCTAssertFalse(UnlockGestureRecognizer.fingerMovedTooFar(from: start, to: movedSlightly))
        XCTAssertTrue(UnlockGestureRecognizer.fingerMovedTooFar(from: start, to: movedTooFar))
    }
}
