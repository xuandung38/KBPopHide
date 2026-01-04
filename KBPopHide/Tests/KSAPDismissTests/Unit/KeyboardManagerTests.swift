@testable import KSAPDismiss
import XCTest

@MainActor
final class KeyboardManagerTests: XCTestCase {
    var manager: KeyboardManager!
    var mockFileSystem: MockFileSystem!
    var mockAuthHelper: MockAuthHelper!

    override func setUp() {
        super.setUp()
        mockFileSystem = MockFileSystem()
        mockAuthHelper = MockAuthHelper()
        // Reset MockUSBDetector
        MockUSBDetector.detectedKeyboards = []

        manager = KeyboardManager(
            fileSystem: mockFileSystem,
            authHelper: mockAuthHelper,
            usbDetector: MockUSBDetector.self
        )
    }

    func testStatusFromEmptyPlist() {
        // Given file doesn't exist
        manager.refreshStatus()

        XCTAssertEqual(manager.status, .enabled)
        XCTAssertFalse(manager.isKSADisabled)
        XCTAssertNil(manager.configuredKeyboards)
    }

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

    func testDisableKSAWithNoKeyboards() async throws {
        MockUSBDetector.detectedKeyboards = []

        try await manager.disableKSA()

        XCTAssertFalse(mockAuthHelper.executedCommands.isEmpty)
        // Should use fallbacks
        let command = mockAuthHelper.executedCommands.first ?? ""
        XCTAssertTrue(command.contains("1452-635-0")) // Apple USB
        XCTAssertTrue(command.contains("1452-636-0")) // Apple Wireless
    }

    func testDisableKSAWithDetectedKeyboards() async throws {
        MockUSBDetector.detectedKeyboards = [(123, 456)]

        try await manager.disableKSA()

        XCTAssertFalse(mockAuthHelper.executedCommands.isEmpty)
        let command = mockAuthHelper.executedCommands.first ?? ""
        XCTAssertTrue(command.contains("123-456-0"))
    }
}
