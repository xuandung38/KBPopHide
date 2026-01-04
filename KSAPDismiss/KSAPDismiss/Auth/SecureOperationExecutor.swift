import Foundation
import os.log

/// Combines Touch ID auth with XPC operations
@MainActor
final class SecureOperationExecutor {

    static let shared = SecureOperationExecutor()

    private let touchID = TouchIDAuthenticator.shared
    private let xpc = XPCClient.shared
    private let logger = Logger(subsystem: "com.hxd.ksapdismiss", category: "SecureExecutor")

    private init() {}

    // MARK: - Generic Execution

    /// Execute privileged operation with Touch ID
    /// - Parameters:
    ///   - reason: Reason shown to user for biometric prompt
    ///   - operation: The async operation to execute after authentication
    /// - Returns: Result of the operation
    func execute<T>(
        reason: String,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        logger.info("Starting secure operation: \(reason)")

        // Step 1: Authenticate with Touch ID
        do {
            try await touchID.authenticate(reason: reason)
        } catch let error as TouchIDError where error.shouldFallbackToPassword {
            logger.info("Falling back to password authentication")
            // Fall back to password-based auth
            try await touchID.authenticateWithFallback(reason: reason)
        }

        // Step 2: Ensure XPC connection
        if !xpc.isConnected {
            logger.info("Establishing XPC connection")
            try await xpc.connectWithRetry()
        }

        // Step 3: Execute operation
        logger.info("Executing privileged operation")
        return try await operation()
    }

    // MARK: - Keyboard Operations

    /// Add keyboard entries with Touch ID authentication
    /// - Parameter entries: Keyboard entries to add
    func addKeyboardEntries(_ entries: [(identifier: String, type: Int)]) async throws {
        try await execute(reason: "Configure keyboard settings") {
            try await self.xpc.addKeyboardEntries(entries)
        }
        logger.info("Added \(entries.count) keyboard entries")
    }

    /// Remove all keyboard entries with Touch ID authentication
    func removeAllKeyboardEntries() async throws {
        try await execute(reason: "Reset keyboard settings") {
            try await self.xpc.removeAllKeyboardEntries()
        }
        logger.info("Removed all keyboard entries")
    }

    /// Get keyboard status (no auth required - read-only)
    func getKeyboardStatus() async throws -> (hasEntries: Bool, keyboards: [String]?) {
        // Ensure connection but no auth needed for read
        if !xpc.isConnected {
            try await xpc.connectWithRetry()
        }
        return try await xpc.getKeyboardStatus()
    }
}
