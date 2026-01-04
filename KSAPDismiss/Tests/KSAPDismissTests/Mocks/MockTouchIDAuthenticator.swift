import Foundation
@testable import KSAPDismiss

/// Mock Touch ID Authenticator for testing
/// Simulates biometric authentication without real LAContext
@MainActor
final class MockTouchIDAuthenticator: @unchecked Sendable {

    // MARK: - Call Tracking

    private(set) var authenticateCalled = false
    private(set) var authenticateWithFallbackCalled = false
    private(set) var lastAuthReason: String?
    private(set) var callCount = 0

    // MARK: - Configurable Behavior

    var shouldAuthenticateSucceed = true
    var shouldFallbackSucceed = true
    var authError: TouchIDError?

    // MARK: - Authentication Methods

    func authenticate(reason: String) async throws {
        authenticateCalled = true
        lastAuthReason = reason
        callCount += 1

        if let error = authError {
            throw error
        }

        if !shouldAuthenticateSucceed {
            throw TouchIDError.failed
        }
    }

    func authenticateWithFallback(reason: String) async throws {
        authenticateWithFallbackCalled = true
        lastAuthReason = reason
        callCount += 1

        if !shouldFallbackSucceed {
            throw TouchIDError.failed
        }
    }

    // MARK: - Test Helpers

    func reset() {
        authenticateCalled = false
        authenticateWithFallbackCalled = false
        lastAuthReason = nil
        callCount = 0

        shouldAuthenticateSucceed = true
        shouldFallbackSucceed = true
        authError = nil
    }

    /// Simulate user cancellation
    func simulateUserCancel() {
        authError = TouchIDError.userCanceled
        shouldAuthenticateSucceed = false
    }

    /// Simulate biometric not enrolled (fallback needed)
    func simulateBiometricNotAvailable() {
        authError = TouchIDError.notEnrolled  // notEnrolled has shouldFallbackToPassword = true
        shouldAuthenticateSucceed = false
    }
}
