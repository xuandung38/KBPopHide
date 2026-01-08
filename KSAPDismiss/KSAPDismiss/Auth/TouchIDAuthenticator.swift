import Foundation
import LocalAuthentication
import os.log

/// Touch ID / Biometric authentication wrapper
@MainActor
final class TouchIDAuthenticator: ObservableObject {

    static let shared = TouchIDAuthenticator()

    @Published private(set) var isBiometricAvailable = false
    @Published private(set) var biometricType: LABiometryType = .none

    private let logger = Logger(subsystem: "com.hxd.ksapdismiss", category: "TouchID")

    private init() {
        checkBiometricAvailability()
    }

    // MARK: - Availability Check

    /// Check if biometric auth is available
    func checkBiometricAvailability() {
        let context = LAContext()
        var error: NSError?
        isBiometricAvailable = context.canEvaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            error: &error
        )
        biometricType = context.biometryType

        if let error = error {
            logger.warning("Biometric not available: \(error.localizedDescription)")
        } else {
            logger.info("Biometric available: \(self.biometricName)")
        }
    }

    /// Human-readable biometric type name
    var biometricName: String {
        switch biometricType {
        case .touchID: return "Touch ID"
        case .faceID: return "Face ID"
        case .opticID: return "Optic ID"
        default: return "Biometric"
        }
    }

    // MARK: - Authentication

    /// Authenticate user with biometrics only
    /// - Parameter reason: Reason shown to user
    /// - Throws: TouchIDError on failure
    func authenticate(reason: String) async throws {
        logger.info("Authenticating with \(self.biometricName)")

        // Create fresh context for each auth attempt
        let context = LAContext()
        context.localizedFallbackTitle = "Use Password"
        context.localizedCancelTitle = "Cancel"

        // Check availability
        var error: NSError?
        guard context.canEvaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            error: &error
        ) else {
            logger.error("Biometric not available: \(error?.localizedDescription ?? "unknown")")
            // Handle NSError from canEvaluatePolicy (different from LAError)
            throw mapCanEvaluatePolicyError(error)
        }

        // Evaluate biometric
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            if !success {
                logger.warning("Authentication returned false")
                throw TouchIDError.failed
            }
            logger.info("Authentication successful")
        } catch let laError as LAError {
            logger.warning("LAError: \(laError.localizedDescription)")
            throw mapLAError(laError)
        }
    }

    /// Authenticate with fallback to device passcode
    /// - Parameter reason: Reason shown to user
    /// - Throws: TouchIDError on failure
    func authenticateWithFallback(reason: String) async throws {
        logger.info("Authenticating with fallback to passcode")

        let context = LAContext()

        var error: NSError?
        guard context.canEvaluatePolicy(
            .deviceOwnerAuthentication,  // Includes passcode fallback
            error: &error
        ) else {
            logger.error("Device auth not available: \(error?.localizedDescription ?? "unknown")")
            throw mapCanEvaluatePolicyError(error)
        }

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: reason
            )
            if !success {
                logger.warning("Authentication with fallback returned false")
                throw TouchIDError.failed
            }
            logger.info("Authentication with fallback successful")
        } catch let laError as LAError {
            logger.warning("LAError with fallback: \(laError.localizedDescription)")
            throw mapLAError(laError)
        }
    }

    // MARK: - Private

    /// Map NSError from canEvaluatePolicy to TouchIDError
    private func mapCanEvaluatePolicyError(_ error: NSError?) -> TouchIDError {
        guard let error = error else {
            return .notAvailable("Biometric authentication not available")
        }

        let laErrorCode = LAError.Code(rawValue: error.code)

        switch laErrorCode {
        case .biometryNotAvailable:
            return .notAvailable("Biometric hardware not available")
        case .biometryNotEnrolled:
            return .notEnrolled
        case .biometryNotPaired:
            // "Biometric accessory is not paired" - e.g., external Touch ID keyboard
            return .notPaired
        case .passcodeNotSet:
            return .passcodeNotSet
        case .biometryLockout:
            return .lockout
        default:
            // Unknown error from canEvaluatePolicy
            return .notAvailable(error.localizedDescription)
        }
    }

    /// Map LAError from evaluatePolicy to TouchIDError
    private func mapLAError(_ error: LAError) -> TouchIDError {
        switch error.code {
        case .userCancel:
            return .userCanceled

        case .userFallback:
            return .userFallback

        case .biometryNotAvailable:
            return .notAvailable("Biometric hardware not available")

        case .biometryNotEnrolled:
            return .notEnrolled

        case .biometryNotPaired:
            // External biometric device not connected
            return .notPaired

        case .biometryLockout:
            return .lockout

        case .authenticationFailed:
            return .failed

        case .appCancel:
            // App invalidated context during evaluation
            return .appCanceled

        case .invalidContext:
            // Context configuration error (developer error)
            return .invalidContext

        case .notInteractive:
            // UI required but not allowed (e.g., background)
            return .notInteractive

        case .passcodeNotSet:
            // Device has no passcode set
            return .passcodeNotSet

        case .systemCancel:
            // System interrupted authentication
            return .systemCanceled

        @unknown default:
            return .unknown(error.localizedDescription)
        }
    }
}

// MARK: - Errors

enum TouchIDError: LocalizedError {
    case notAvailable(String?)
    case notEnrolled
    case notPaired
    case lockout
    case passcodeNotSet
    case userCanceled
    case userFallback
    case failed
    case appCanceled
    case systemCanceled
    case invalidContext
    case notInteractive
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .notAvailable(let reason):
            return reason ?? "Biometric authentication not available"

        case .notEnrolled:
            return "No biometric data enrolled. Please set up Touch ID in System Settings."

        case .notPaired:
            return "Biometric accessory is not paired. Please connect your Touch ID keyboard or enable Touch ID."

        case .lockout:
            return "Biometric locked. Please use password to unlock."

        case .passcodeNotSet:
            return "Device passcode not set. Please set up a passcode in System Settings."

        case .userCanceled:
            return nil  // Silent - user chose to cancel

        case .userFallback:
            return nil  // User wants password

        case .failed:
            return "Authentication failed. Please try again."

        case .appCanceled:
            return "Authentication was canceled by the app. Please try again."

        case .systemCanceled:
            return "Authentication was interrupted by the system. Please try again."

        case .invalidContext:
            return "Authentication context error. Please restart the app."

        case .notInteractive:
            return "Authentication requires user interaction but is not available in current context."

        case .unknown(let msg):
            return msg
        }
    }

    /// Whether to show password fallback
    var shouldFallbackToPassword: Bool {
        switch self {
        case .userFallback, .lockout, .notEnrolled, .notPaired, .passcodeNotSet:
            return true
        default:
            return false
        }
    }

    /// Whether error should be shown to user
    var shouldShowAlert: Bool {
        switch self {
        case .userCanceled, .userFallback:
            return false
        default:
            return true
        }
    }
}
