
import XCTest
@testable import KSAPDismiss

final class KeyboardManagerTests: XCTestCase {
    var manager: KeyboardManager!
    var mockFileSystem: MockFileSystem!

    @MainActor
    override func setUp() {
        super.setUp()
        mockFileSystem = MockFileSystem()
        // Reset MockUSBDetector
        MockUSBDetector.detectedKeyboards = []

        // Use test initializer with mock file system
        manager = KeyboardManager(
            fileSystem: mockFileSystem,
            usbDetector: MockUSBDetector.self
        )
    }

    // MARK: - Status Tests

    @MainActor
    func testStatusFromEmptyPlist() {
        // Given file doesn't exist
        manager.refreshStatus()

        XCTAssertEqual(manager.status, .enabled)
        XCTAssertFalse(manager.isKSADisabled)
        XCTAssertNil(manager.configuredKeyboards)
    }

    @MainActor
    func testStatusFromValidPlist() throws {
        // Create a fake plist with configured keyboards
        let plistDict: [String: Any] = [
            "keyboardtype": [
                "1452-635-0": 40
            ]
        ]
        let data = try PropertyListSerialization.data(fromPropertyList: plistDict, format: .xml, options: 0)
        mockFileSystem.files["/Library/Preferences/com.apple.keyboardtype.plist"] = data

        manager.refreshStatus()

        XCTAssertEqual(manager.status, .disabled)
        XCTAssertTrue(manager.isKSADisabled)
        XCTAssertEqual(manager.configuredKeyboards?.count, 1)
        XCTAssertEqual(manager.configuredKeyboards?.first, "1452-635-0")
    }

    @MainActor
    func testStatusWithMultipleKeyboards() throws {
        let plistDict: [String: Any] = [
            "keyboardtype": [
                "1452-635-0": 40,
                "1452-636-0": 40,
                "123-456-0": 41
            ]
        ]
        let data = try PropertyListSerialization.data(fromPropertyList: plistDict, format: .xml, options: 0)
        mockFileSystem.files["/Library/Preferences/com.apple.keyboardtype.plist"] = data

        manager.refreshStatus()

        XCTAssertEqual(manager.status, .disabled)
        XCTAssertTrue(manager.isKSADisabled)
        XCTAssertEqual(manager.configuredKeyboards?.count, 3)
    }

    @MainActor
    func testStatusWithEmptyKeyboardDict() throws {
        let plistDict: [String: Any] = [
            "keyboardtype": [String: Int]()
        ]
        let data = try PropertyListSerialization.data(fromPropertyList: plistDict, format: .xml, options: 0)
        mockFileSystem.files["/Library/Preferences/com.apple.keyboardtype.plist"] = data

        manager.refreshStatus()

        XCTAssertEqual(manager.status, .enabled)
        XCTAssertFalse(manager.isKSADisabled)
    }

    // MARK: - Keyboard Detection Tests

    @MainActor
    func testAutoConfigureSkipsAlreadyConfigured() async throws {
        // Setup: keyboard already in configuredKeyboards
        let plistDict: [String: Any] = [
            "keyboardtype": [
                "1452-635-0": 40
            ]
        ]
        let data = try PropertyListSerialization.data(fromPropertyList: plistDict, format: .xml, options: 0)
        mockFileSystem.files["/Library/Preferences/com.apple.keyboardtype.plist"] = data
        manager.refreshStatus()

        // Try to auto-configure same keyboard
        await manager.autoConfigureKeyboard(vendorID: 1452, productID: 635)

        // Should still have same config (no duplicate attempts)
        XCTAssertEqual(manager.configuredKeyboards?.count, 1)
    }

    // MARK: - Validation Tests

    @MainActor
    func testKeyboardIdentifierValidation() {
        // Valid identifiers should not throw
        XCTAssertNoThrow(try validateIdentifier("1452-635-0"))
        XCTAssertNoThrow(try validateIdentifier("0-0-0"))
        XCTAssertNoThrow(try validateIdentifier("12345-67890-0"))

        // Invalid identifiers should throw
        XCTAssertThrowsError(try validateIdentifier("invalid"))
        XCTAssertThrowsError(try validateIdentifier("1452-635"))
        XCTAssertThrowsError(try validateIdentifier("abc-def-ghi"))
    }

    private func validateIdentifier(_ identifier: String) throws {
        let components = identifier.split(separator: "-")
        guard components.count == 3,
              components.allSatisfy({ Int($0) != nil }) else {
            throw NSError(domain: "Test", code: -1)
        }
    }
}
