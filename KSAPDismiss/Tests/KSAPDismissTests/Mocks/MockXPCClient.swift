import Foundation
@testable import KSAPDismiss

/// Mock XPC Client for unit testing
/// Implements XPCClientProtocol without actual XPC communication
@MainActor
final class MockXPCClient: XPCClientProtocol, @unchecked Sendable {

    // MARK: - State

    var isConnected: Bool = false
    var helperVersion: String? = kHelperVersion

    // MARK: - Call Tracking

    private(set) var connectCalled = false
    private(set) var disconnectCalled = false
    private(set) var addKeyboardEntriesCalled = false
    private(set) var removeAllEntriesCalled = false
    private(set) var getKeyboardStatusCalled = false
    private(set) var connectWithRetryCalled = false

    private(set) var lastAddedEntries: [(identifier: String, type: Int)]?
    private(set) var lastRetryAttempts: Int?

    // MARK: - Configurable Behavior

    var shouldConnectSucceed = true
    var addKeyboardResult: Result<Void, Error> = .success(())
    var removeAllResult: Result<Void, Error> = .success(())
    var keyboardStatusResult: (hasEntries: Bool, keyboards: [String]?) = (false, nil)

    // MARK: - XPCClientProtocol Implementation

    func connect() async throws {
        connectCalled = true
        if shouldConnectSucceed {
            isConnected = true
        } else {
            throw XPCError.connectionFailed
        }
    }

    func disconnect() {
        disconnectCalled = true
        isConnected = false
    }

    func connectWithRetry(maxAttempts: Int) async throws {
        connectWithRetryCalled = true
        lastRetryAttempts = maxAttempts
        if shouldConnectSucceed {
            isConnected = true
        } else {
            throw XPCError.connectionFailed
        }
    }

    func addKeyboardEntries(_ entries: [(identifier: String, type: Int)]) async throws {
        addKeyboardEntriesCalled = true
        lastAddedEntries = entries
        try addKeyboardResult.get()
    }

    func removeAllKeyboardEntries() async throws {
        removeAllEntriesCalled = true
        try removeAllResult.get()
    }

    func getKeyboardStatus() async throws -> (hasEntries: Bool, keyboards: [String]?) {
        getKeyboardStatusCalled = true
        return keyboardStatusResult
    }

    // MARK: - Test Helpers

    func reset() {
        isConnected = false
        helperVersion = kHelperVersion

        connectCalled = false
        disconnectCalled = false
        addKeyboardEntriesCalled = false
        removeAllEntriesCalled = false
        getKeyboardStatusCalled = false
        connectWithRetryCalled = false

        lastAddedEntries = nil
        lastRetryAttempts = nil

        shouldConnectSucceed = true
        addKeyboardResult = .success(())
        removeAllResult = .success(())
        keyboardStatusResult = (false, nil)
    }
}
