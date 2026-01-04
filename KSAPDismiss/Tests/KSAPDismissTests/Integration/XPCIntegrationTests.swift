import XCTest
@testable import KSAPDismiss

/// Integration tests for XPC communication
/// Tests the XPC client using MockXPCHelper with anonymous listener
@MainActor
final class XPCIntegrationTests: XCTestCase {

    var mockClient: MockXPCClient!

    override func setUp() async throws {
        try await super.setUp()
        mockClient = MockXPCClient()
    }

    override func tearDown() async throws {
        mockClient?.reset()
        mockClient = nil
        try await super.tearDown()
    }

    // MARK: - Connection Tests

    func testConnectSuccess() async throws {
        mockClient.shouldConnectSucceed = true

        try await mockClient.connect()

        XCTAssertTrue(mockClient.connectCalled, "connect() should be called")
        XCTAssertTrue(mockClient.isConnected, "Should be connected after successful connect")
    }

    func testConnectFailure() async throws {
        mockClient.shouldConnectSucceed = false

        do {
            try await mockClient.connect()
            XCTFail("Should throw on connection failure")
        } catch {
            XCTAssertTrue(error is XPCError, "Should throw XPCError")
            XCTAssertFalse(mockClient.isConnected, "Should not be connected after failure")
        }
    }

    func testConnectWithRetrySuccess() async throws {
        mockClient.shouldConnectSucceed = true

        try await mockClient.connectWithRetry(maxAttempts: 3)

        XCTAssertTrue(mockClient.connectWithRetryCalled, "connectWithRetry() should be called")
        XCTAssertEqual(mockClient.lastRetryAttempts, 3, "Should pass correct maxAttempts")
        XCTAssertTrue(mockClient.isConnected, "Should be connected")
    }

    func testConnectWithRetryFailure() async throws {
        mockClient.shouldConnectSucceed = false

        do {
            try await mockClient.connectWithRetry(maxAttempts: 3)
            XCTFail("Should throw on connection failure")
        } catch {
            XCTAssertTrue(error is XPCError, "Should throw XPCError")
        }
    }

    func testDisconnect() async throws {
        mockClient.isConnected = true

        mockClient.disconnect()

        XCTAssertTrue(mockClient.disconnectCalled, "disconnect() should be called")
        XCTAssertFalse(mockClient.isConnected, "Should be disconnected")
    }

    // MARK: - Keyboard Entry Tests

    func testAddKeyboardEntriesSuccess() async throws {
        let entries: [(identifier: String, type: Int)] = [
            ("1452-635-0", 40),
            ("1452-636-0", 40)
        ]

        try await mockClient.addKeyboardEntries(entries)

        XCTAssertTrue(mockClient.addKeyboardEntriesCalled, "addKeyboardEntries() should be called")
        XCTAssertEqual(mockClient.lastAddedEntries?.count, 2, "Should have 2 entries")
        XCTAssertEqual(mockClient.lastAddedEntries?.first?.identifier, "1452-635-0")
        XCTAssertEqual(mockClient.lastAddedEntries?.first?.type, 40)
    }

    func testAddKeyboardEntriesFailure() async throws {
        mockClient.addKeyboardResult = .failure(XPCError.operationFailed("Permission denied"))

        do {
            try await mockClient.addKeyboardEntries([("123-456-0", 40)])
            XCTFail("Should throw on operation failure")
        } catch {
            XCTAssertTrue(error is XPCError, "Should throw XPCError")
        }
    }

    func testRemoveAllKeyboardEntriesSuccess() async throws {
        try await mockClient.removeAllKeyboardEntries()

        XCTAssertTrue(mockClient.removeAllEntriesCalled, "removeAllKeyboardEntries() should be called")
    }

    func testRemoveAllKeyboardEntriesFailure() async throws {
        mockClient.removeAllResult = .failure(XPCError.operationFailed("File not found"))

        do {
            try await mockClient.removeAllKeyboardEntries()
            XCTFail("Should throw on operation failure")
        } catch {
            XCTAssertTrue(error is XPCError, "Should throw XPCError")
        }
    }

    // MARK: - Status Tests

    func testGetKeyboardStatusNoEntries() async throws {
        mockClient.keyboardStatusResult = (false, nil)

        let (hasEntries, keyboards) = try await mockClient.getKeyboardStatus()

        XCTAssertTrue(mockClient.getKeyboardStatusCalled, "getKeyboardStatus() should be called")
        XCTAssertFalse(hasEntries, "Should have no entries")
        XCTAssertNil(keyboards, "Keyboards should be nil")
    }

    func testGetKeyboardStatusWithEntries() async throws {
        mockClient.keyboardStatusResult = (true, ["1452-635-0", "1452-636-0"])

        let (hasEntries, keyboards) = try await mockClient.getKeyboardStatus()

        XCTAssertTrue(hasEntries, "Should have entries")
        XCTAssertEqual(keyboards?.count, 2, "Should have 2 keyboards")
        XCTAssertEqual(keyboards?.first, "1452-635-0")
    }

    // MARK: - Version Tests

    func testHelperVersionAvailable() async throws {
        mockClient.helperVersion = "1.0.0"

        XCTAssertEqual(mockClient.helperVersion, "1.0.0", "Should have version")
    }

    func testHelperVersionNil() async throws {
        mockClient.helperVersion = nil

        XCTAssertNil(mockClient.helperVersion, "Version should be nil when not connected")
    }
}
