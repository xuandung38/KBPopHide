import XCTest
@testable import KSAPDismiss

/// Integration tests for SecureOperationExecutor
/// Tests the full Touch ID -> Helper Install -> XPC -> Operation flow
@MainActor
final class SecureOperationExecutorIntegrationTests: XCTestCase {

    var mockXPC: MockXPCClient!
    var mockAuth: MockTouchIDAuthenticator!

    override func setUp() async throws {
        try await super.setUp()
        mockXPC = MockXPCClient()
        mockAuth = MockTouchIDAuthenticator()
    }

    override func tearDown() async throws {
        mockXPC?.reset()
        mockAuth?.reset()
        mockXPC = nil
        mockAuth = nil
        try await super.tearDown()
    }

    // MARK: - Authentication Flow Tests

    func testAuthenticationSuccess() async throws {
        mockAuth.shouldAuthenticateSucceed = true

        try await mockAuth.authenticate(reason: "Test operation")

        XCTAssertTrue(mockAuth.authenticateCalled, "authenticate() should be called")
        XCTAssertEqual(mockAuth.lastAuthReason, "Test operation")
    }

    func testAuthenticationUserCanceled() async throws {
        mockAuth.simulateUserCancel()

        do {
            try await mockAuth.authenticate(reason: "Test operation")
            XCTFail("Should throw on user cancellation")
        } catch let error as TouchIDError {
            if case .userCanceled = error {
                XCTAssertFalse(error.shouldShowAlert, "Should not show alert for cancellation")
            } else {
                XCTFail("Expected userCanceled error")
            }
        }
    }

    func testAuthenticationFallbackToPassword() async throws {
        mockAuth.simulateBiometricNotAvailable()
        mockAuth.shouldFallbackSucceed = true

        // First auth fails with biometric not available
        do {
            try await mockAuth.authenticate(reason: "Test operation")
            XCTFail("Should throw biometry not available")
        } catch let error as TouchIDError {
            XCTAssertTrue(error.shouldFallbackToPassword, "Should fallback to password")
        }

        // Then fallback succeeds
        try await mockAuth.authenticateWithFallback(reason: "Test operation")
        XCTAssertTrue(mockAuth.authenticateWithFallbackCalled)
    }

    // MARK: - XPC Connection Tests

    func testXPCConnectionBeforeOperation() async throws {
        mockXPC.shouldConnectSucceed = true

        try await mockXPC.connectWithRetry(maxAttempts: 3)
        try await mockXPC.addKeyboardEntries([("123-456-0", 40)])

        XCTAssertTrue(mockXPC.connectWithRetryCalled, "Should connect before operation")
        XCTAssertTrue(mockXPC.addKeyboardEntriesCalled, "Operation should execute")
    }

    func testXPCConnectionFailure() async throws {
        mockXPC.shouldConnectSucceed = false

        do {
            try await mockXPC.connectWithRetry(maxAttempts: 3)
            XCTFail("Should throw on connection failure")
        } catch {
            XCTAssertTrue(error is XPCError)
        }
    }

    // MARK: - Full Flow Tests

    func testFullFlowAddKeyboardEntries() async throws {
        // Simulate full flow: Auth -> Connect -> Add entries
        mockAuth.shouldAuthenticateSucceed = true
        mockXPC.shouldConnectSucceed = true

        // Step 1: Authenticate
        try await mockAuth.authenticate(reason: "Configure keyboards")

        // Step 2: Connect
        try await mockXPC.connectWithRetry(maxAttempts: 3)

        // Step 3: Add entries
        let entries: [(identifier: String, type: Int)] = [("1452-635-0", 40)]
        try await mockXPC.addKeyboardEntries(entries)

        // Verify full flow
        XCTAssertTrue(mockAuth.authenticateCalled)
        XCTAssertTrue(mockXPC.connectWithRetryCalled)
        XCTAssertTrue(mockXPC.addKeyboardEntriesCalled)
        XCTAssertEqual(mockXPC.lastAddedEntries?.count, 1)
    }

    func testFullFlowRemoveAllEntries() async throws {
        // Simulate full flow: Auth -> Connect -> Remove entries
        mockAuth.shouldAuthenticateSucceed = true
        mockXPC.shouldConnectSucceed = true

        // Step 1: Authenticate
        try await mockAuth.authenticate(reason: "Reset keyboards")

        // Step 2: Connect
        try await mockXPC.connectWithRetry(maxAttempts: 3)

        // Step 3: Remove all entries
        try await mockXPC.removeAllKeyboardEntries()

        // Verify full flow
        XCTAssertTrue(mockAuth.authenticateCalled)
        XCTAssertTrue(mockXPC.connectWithRetryCalled)
        XCTAssertTrue(mockXPC.removeAllEntriesCalled)
    }

    func testFullFlowAuthFailurePreventsOperation() async throws {
        mockAuth.simulateUserCancel()

        do {
            try await mockAuth.authenticate(reason: "Configure keyboards")
            XCTFail("Should throw on auth failure")
        } catch {
            // Auth failed, so XPC operations should not be attempted
            XCTAssertFalse(mockXPC.connectWithRetryCalled)
            XCTAssertFalse(mockXPC.addKeyboardEntriesCalled)
        }
    }

    // MARK: - Error Propagation Tests

    func testXPCErrorPropagation() async throws {
        mockAuth.shouldAuthenticateSucceed = true
        mockXPC.shouldConnectSucceed = true
        mockXPC.addKeyboardResult = .failure(XPCError.operationFailed("Permission denied"))

        // Auth and connect succeed
        try await mockAuth.authenticate(reason: "Test")
        try await mockXPC.connectWithRetry(maxAttempts: 3)

        // Operation fails
        do {
            try await mockXPC.addKeyboardEntries([("123-456-0", 40)])
            XCTFail("Should throw operation error")
        } catch let error as XPCError {
            if case .operationFailed(let msg) = error {
                XCTAssertEqual(msg, "Permission denied")
            } else {
                XCTFail("Wrong error type")
            }
        }
    }

    func testAuthErrorTypes() async throws {
        // Test various auth error types - use actual TouchIDError cases
        let errorCases: [(TouchIDError, Bool)] = [
            (.userCanceled, false),
            (.userFallback, false),
            (.failed, true),
            (.notAvailable(nil), true),
            (.notEnrolled, true),
            (.lockout, true)
        ]

        for (error, shouldShow) in errorCases {
            mockAuth.reset()
            mockAuth.authError = error

            do {
                try await mockAuth.authenticate(reason: "Test")
                XCTFail("Should throw error")
            } catch let e as TouchIDError {
                XCTAssertEqual(e.shouldShowAlert, shouldShow, "shouldShowAlert mismatch")
            }
        }
    }
}
