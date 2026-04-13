import XCTest
@testable import BabyLock

final class PasscodeStoreTests: XCTestCase {
    var store: PasscodeStore!

    override func setUp() {
        super.setUp()
        store = PasscodeStore()
        try? store.delete()
    }

    override func tearDown() {
        try? store.delete()
        super.tearDown()
    }

    func testInitiallyHasNoPasscode() {
        XCTAssertFalse(store.hasPasscode)
        XCTAssertNil(store.load())
    }

    func testSaveAndLoad() throws {
        try store.save("1234")
        XCTAssertEqual(store.load(), "1234")
    }

    func testHasPasscodeAfterSave() throws {
        try store.save("5678")
        XCTAssertTrue(store.hasPasscode)
    }

    func testVerifyCorrectPasscode() throws {
        try store.save("9012")
        XCTAssertTrue(store.verify("9012"))
    }

    func testVerifyWrongPasscode() throws {
        try store.save("9012")
        XCTAssertFalse(store.verify("0000"))
    }

    func testVerifyWithNoPasscodeSet() {
        XCTAssertFalse(store.verify("1234"))
    }

    func testSaveOverwritesPrevious() throws {
        try store.save("1111")
        try store.save("2222")
        XCTAssertEqual(store.load(), "2222")
    }

    func testDeleteRemovesPasscode() throws {
        try store.save("1234")
        try store.delete()
        XCTAssertFalse(store.hasPasscode)
        XCTAssertNil(store.load())
    }

    func testDeleteWhenNoneExistsDoesNotThrow() {
        XCTAssertNoThrow(try store.delete())
    }
}
