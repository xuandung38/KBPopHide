
import XCTest
@testable import KSAPDismiss

final class TouchIDAuthenticatorTests: XCTestCase {

    // MARK: - TouchIDError Tests

    func testTouchIDErrorDescriptions() {
        let errorsWithDescriptions: [TouchIDError] = [
            .notAvailable("test reason"),
            .notEnrolled,
            .lockout,
            .failed,
            .unknown("test message")
        ]

        for error in errorsWithDescriptions {
            XCTAssertNotNil(error.errorDescription)
            XCTAssertFalse(error.errorDescription!.isEmpty)
        }
    }

    func testSilentErrorsHaveNoDescription() {
        let silentErrors: [TouchIDError] = [
            .userCanceled,
            .userFallback
        ]

        for error in silentErrors {
            XCTAssertNil(error.errorDescription, "Silent error should have nil description")
        }
    }

    func testNotAvailableErrorDescription() {
        let errorWithReason = TouchIDError.notAvailable("Hardware missing")
        XCTAssertEqual(errorWithReason.errorDescription, "Hardware missing")

        let errorWithoutReason = TouchIDError.notAvailable(nil)
        XCTAssertEqual(errorWithoutReason.errorDescription, "Biometric authentication not available")
    }

    func testNotEnrolledErrorDescription() {
        let error = TouchIDError.notEnrolled
        XCTAssertEqual(error.errorDescription, "No biometric data enrolled. Please set up Touch ID in System Settings.")
    }

    func testLockoutErrorDescription() {
        let error = TouchIDError.lockout
        XCTAssertEqual(error.errorDescription, "Biometric locked. Please use password to unlock.")
    }

    func testFailedErrorDescription() {
        let error = TouchIDError.failed
        XCTAssertEqual(error.errorDescription, "Authentication failed")
    }

    func testUnknownErrorDescription() {
        let error = TouchIDError.unknown("Custom message")
        XCTAssertEqual(error.errorDescription, "Custom message")
    }

    // MARK: - Fallback Behavior Tests

    func testShouldFallbackToPassword() {
        // Errors that should trigger fallback
        XCTAssertTrue(TouchIDError.userFallback.shouldFallbackToPassword)
        XCTAssertTrue(TouchIDError.lockout.shouldFallbackToPassword)
        XCTAssertTrue(TouchIDError.notEnrolled.shouldFallbackToPassword)

        // Errors that should NOT trigger fallback
        XCTAssertFalse(TouchIDError.userCanceled.shouldFallbackToPassword)
        XCTAssertFalse(TouchIDError.failed.shouldFallbackToPassword)
        XCTAssertFalse(TouchIDError.notAvailable(nil).shouldFallbackToPassword)
        XCTAssertFalse(TouchIDError.unknown("test").shouldFallbackToPassword)
    }

    // MARK: - Alert Display Tests

    func testShouldShowAlert() {
        // Errors that should show alert
        XCTAssertTrue(TouchIDError.notAvailable(nil).shouldShowAlert)
        XCTAssertTrue(TouchIDError.notEnrolled.shouldShowAlert)
        XCTAssertTrue(TouchIDError.lockout.shouldShowAlert)
        XCTAssertTrue(TouchIDError.failed.shouldShowAlert)
        XCTAssertTrue(TouchIDError.unknown("test").shouldShowAlert)

        // Silent errors (user-initiated cancellation)
        XCTAssertFalse(TouchIDError.userCanceled.shouldShowAlert)
        XCTAssertFalse(TouchIDError.userFallback.shouldShowAlert)
    }

    // MARK: - Singleton Tests

    @MainActor
    func testTouchIDAuthenticatorSingleton() {
        let auth1 = TouchIDAuthenticator.shared
        let auth2 = TouchIDAuthenticator.shared
        XCTAssertTrue(auth1 === auth2)
    }

    @MainActor
    func testBiometricNameMapping() {
        let auth = TouchIDAuthenticator.shared
        // Just verify it returns a non-empty string
        XCTAssertFalse(auth.biometricName.isEmpty)
    }
}
