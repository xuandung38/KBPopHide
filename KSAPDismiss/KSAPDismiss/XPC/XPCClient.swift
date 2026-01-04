import Foundation
import os.log

/// XPC Client for communicating with privileged helper
@MainActor
final class XPCClient: ObservableObject {

    static let shared = XPCClient()

    @Published private(set) var isConnected = false
    @Published private(set) var helperVersion: String?

    private var connection: NSXPCConnection?
    private let connectionQueue = DispatchQueue(label: "com.hxd.ksapdismiss.xpc")
    private let logger = Logger(subsystem: "com.hxd.ksapdismiss", category: "XPCClient")

    private init() {}

    // MARK: - Connection Management

    /// Establish connection to helper
    func connect() async throws {
        logger.info("Connecting to helper...")

        return try await withCheckedThrowingContinuation { continuation in
            connectionQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: XPCError.connectionFailed)
                    return
                }

                // Create connection
                let conn = NSXPCConnection(
                    machServiceName: kHelperBundleID,
                    options: .privileged
                )
                conn.remoteObjectInterface = NSXPCInterface(with: HelperProtocol.self)

                conn.invalidationHandler = { [weak self] in
                    Task { @MainActor in
                        self?.logger.warning("XPC connection invalidated")
                        self?.isConnected = false
                        self?.connection = nil
                    }
                }

                conn.interruptionHandler = { [weak self] in
                    Task { @MainActor in
                        self?.logger.warning("XPC connection interrupted")
                        self?.isConnected = false
                    }
                }

                conn.resume()

                // Update connection on main actor
                Task { @MainActor in
                    self.connection = conn
                }

                // Verify connection by getting version
                guard let helper = conn.remoteObjectProxyWithErrorHandler({ error in
                    self.logger.error("XPC error: \(error.localizedDescription)")
                    continuation.resume(throwing: XPCError.connectionFailed)
                }) as? HelperProtocol else {
                    continuation.resume(throwing: XPCError.connectionFailed)
                    return
                }

                helper.getVersion { [weak self] version in
                    Task { @MainActor in
                        self?.helperVersion = version
                        self?.isConnected = true
                        self?.logger.info("Connected to helper v\(version)")
                    }
                    continuation.resume()
                }
            }
        }
    }

    /// Disconnect from helper
    func disconnect() {
        logger.info("Disconnecting from helper")
        connection?.invalidate()
        connection = nil
        isConnected = false
        helperVersion = nil
    }

    // MARK: - Helper Operations

    /// Add keyboard entries
    func addKeyboardEntries(_ entries: [(identifier: String, type: Int)]) async throws {
        let helper = try getHelper()

        let entriesDict = entries.map { entry in
            ["identifier": entry.identifier, "type": entry.type] as [String: Any]
        }

        logger.info("Adding \(entries.count) keyboard entries")

        return try await withCheckedThrowingContinuation { continuation in
            helper.addKeyboardEntries(entriesDict) { success, error in
                if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: XPCError.operationFailed(error ?? "Unknown error"))
                }
            }
        }
    }

    /// Remove all keyboard entries (enable KSA)
    func removeAllKeyboardEntries() async throws {
        let helper = try getHelper()

        logger.info("Removing all keyboard entries")

        return try await withCheckedThrowingContinuation { continuation in
            helper.removeAllKeyboardEntries { success, error in
                if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: XPCError.operationFailed(error ?? "Unknown error"))
                }
            }
        }
    }

    /// Get keyboard status
    func getKeyboardStatus() async throws -> (hasEntries: Bool, keyboards: [String]?) {
        let helper = try getHelper()

        return try await withCheckedThrowingContinuation { continuation in
            helper.getKeyboardStatus { hasEntries, keyboards in
                continuation.resume(returning: (hasEntries, keyboards))
            }
        }
    }

    // MARK: - Private

    private func getHelper() throws -> HelperProtocol {
        guard let connection = connection,
              let helper = connection.remoteObjectProxyWithErrorHandler({ _ in })
                as? HelperProtocol else {
            throw XPCError.notConnected
        }
        return helper
    }
}

// MARK: - Connection State Management

extension XPCClient {

    /// Check if helper is installed
    var isHelperAvailable: Bool {
        FileManager.default.fileExists(
            atPath: "/Library/PrivilegedHelperTools/\(kHelperBundleID)"
        )
    }

    /// Check helper version compatibility
    func checkVersionCompatibility() -> Bool {
        guard let version = helperVersion else { return false }
        return version == kHelperVersion
    }
}

// MARK: - Retry Logic

extension XPCClient {

    /// Connect with retry
    func connectWithRetry(maxAttempts: Int = 3) async throws {
        var lastError: Error?

        for attempt in 1...maxAttempts {
            do {
                try await connect()
                return
            } catch {
                lastError = error
                logger.warning("Connection attempt \(attempt)/\(maxAttempts) failed: \(error.localizedDescription)")
                if attempt < maxAttempts {
                    try await Task.sleep(nanoseconds: 500_000_000) // 500ms
                }
            }
        }

        throw lastError ?? XPCError.connectionFailed
    }

    /// Execute operation with auto-reconnect
    func withConnection<T>(_ operation: () async throws -> T) async throws -> T {
        if !isConnected {
            try await connectWithRetry()
        }

        do {
            return try await operation()
        } catch XPCError.notConnected {
            // Try reconnect once
            try await connect()
            return try await operation()
        }
    }
}

// MARK: - Errors

enum XPCError: LocalizedError {
    case notConnected
    case connectionFailed
    case operationFailed(String)
    case helperNotInstalled

    var errorDescription: String? {
        switch self {
        case .notConnected:
            return "Not connected to helper"
        case .connectionFailed:
            return "Failed to connect to helper. Please reinstall."
        case .operationFailed(let msg):
            return "Operation failed: \(msg)"
        case .helperNotInstalled:
            return "Helper tool not installed. Please complete setup first."
        }
    }
}
