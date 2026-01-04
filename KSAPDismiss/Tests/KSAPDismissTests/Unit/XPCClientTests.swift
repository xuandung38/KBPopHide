
import XCTest
@testable import KSAPDismiss

final class XPCClientTests: XCTestCase {

    // MARK: - XPCError Tests

    func testXPCErrorDescriptions() {
        let errors: [XPCError] = [
            .notConnected,
            .connectionFailed,
            .operationFailed("test message"),
            .helperNotInstalled
        ]

        for error in errors {
            XCTAssertNotNil(error.errorDescription)
            XCTAssertFalse(error.errorDescription!.isEmpty)
        }
    }

    func testNotConnectedErrorDescription() {
        let error = XPCError.notConnected
        XCTAssertEqual(error.errorDescription, "Not connected to helper")
    }

    func testConnectionFailedErrorDescription() {
        let error = XPCError.connectionFailed
        XCTAssertEqual(error.errorDescription, "Failed to connect to helper. Please reinstall.")
    }

    func testOperationFailedErrorDescription() {
        let error = XPCError.operationFailed("Custom error")
        XCTAssertEqual(error.errorDescription, "Operation failed: Custom error")
    }

    func testHelperNotInstalledErrorDescription() {
        let error = XPCError.helperNotInstalled
        XCTAssertEqual(error.errorDescription, "Helper tool not installed. Please complete setup first.")
    }

    // MARK: - Protocol Constants Tests

    func testHelperBundleID() {
        XCTAssertEqual(kHelperBundleID, "com.hxd.ksapdismiss.helper")
    }

    func testHelperVersion() {
        XCTAssertEqual(kHelperVersion, "1.0.0")
    }

    // MARK: - XPCClient State Tests

    @MainActor
    func testXPCClientSingleton() {
        let client1 = XPCClient.shared
        let client2 = XPCClient.shared
        XCTAssertTrue(client1 === client2)
    }

    @MainActor
    func testInitialConnectionState() {
        let client = XPCClient.shared
        XCTAssertFalse(client.isConnected)
        XCTAssertNil(client.helperVersion)
    }

    @MainActor
    func testIsHelperAvailableChecksPaths() {
        let client = XPCClient.shared
        // Helper not installed in test environment
        XCTAssertFalse(client.isHelperAvailable)
    }

    @MainActor
    func testCheckVersionCompatibilityWithoutConnection() {
        let client = XPCClient.shared
        // No version set, should return false
        XCTAssertFalse(client.checkVersionCompatibility())
    }
}
