import XCTest
@testable import BabyLock

final class URLSchemeHandlerTests: XCTestCase {
    func testParsesValidBabyLockURL() {
        let url = URL(string: "babylock://open?url=https%3A%2F%2Fwww.youtube.com%2Fwatch%3Fv%3Dabc123")!
        let result = URLSchemeHandler.parse(url)
        XCTAssertEqual(result, URL(string: "https://www.youtube.com/watch?v=abc123"))
    }

    func testReturnsNilForWrongScheme() {
        let url = URL(string: "https://example.com")!
        let result = URLSchemeHandler.parse(url)
        XCTAssertNil(result)
    }

    func testReturnsNilForWrongHost() {
        let url = URL(string: "babylock://wrong?url=https%3A%2F%2Fexample.com")!
        let result = URLSchemeHandler.parse(url)
        XCTAssertNil(result)
    }

    func testReturnsNilForMissingURLParam() {
        let url = URL(string: "babylock://open")!
        let result = URLSchemeHandler.parse(url)
        XCTAssertNil(result)
    }

    func testReturnsNilForEmptyURLParam() {
        let url = URL(string: "babylock://open?url=")!
        let result = URLSchemeHandler.parse(url)
        XCTAssertNil(result)
    }

    func testReturnsNilForInvalidURLParam() {
        let url = URL(string: "babylock://open?url=not%20a%20url")!
        let result = URLSchemeHandler.parse(url)
        XCTAssertNil(result)
    }

    func testBuildsBabyLockURL() {
        let contentURL = URL(string: "https://www.youtube.com/watch?v=abc123")!
        let result = URLSchemeHandler.buildOpenURL(for: contentURL)
        XCTAssertEqual(result.scheme, "babylock")
        XCTAssertEqual(result.host, "open")
        let parsed = URLSchemeHandler.parse(result)
        XCTAssertEqual(parsed, contentURL)
    }
}
