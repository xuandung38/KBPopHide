import Foundation

/// Protocol for XPC client to enable dependency injection in tests
@MainActor
protocol XPCClientProtocol: Sendable {
    var isConnected: Bool { get }
    var helperVersion: String? { get }

    func connect() async throws
    func disconnect()
    func connectWithRetry(maxAttempts: Int) async throws

    func addKeyboardEntries(_ entries: [(identifier: String, type: Int)]) async throws
    func removeAllKeyboardEntries() async throws
    func getKeyboardStatus() async throws -> (hasEntries: Bool, keyboards: [String]?)
}

// Make XPCClient conform to the protocol
extension XPCClient: XPCClientProtocol {}
