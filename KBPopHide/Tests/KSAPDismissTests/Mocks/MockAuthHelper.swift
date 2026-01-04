@testable import KSAPDismiss
import Foundation

/// Mock authorization helper for testing privileged command execution
final class MockAuthHelper: AuthorizationProtocol, @unchecked Sendable {
    // Recorded commands (backward compatible)
    var executedCommands: [String] = []

    // Detailed command recording
    var executedBatchCommands: [String] = []
    var executedPrivilegedCommands: [(command: String, args: [String])] = []

    // Call counts
    private(set) var batchCallCount = 0
    private(set) var privilegedCallCount = 0

    // Error simulation
    var shouldThrowError: Error?

    func executeBatchShellCommand(_ shellCommand: String) throws {
        batchCallCount += 1
        if let error = shouldThrowError { throw error }
        executedBatchCommands.append(shellCommand)
        executedCommands.append(shellCommand)
    }

    func executePrivileged(command: String, args: [String]) throws {
        privilegedCallCount += 1
        if let error = shouldThrowError { throw error }
        executedPrivilegedCommands.append((command, args))
        executedCommands.append("\(command) \(args.joined(separator: " "))")
    }

    /// Reset all state for test isolation
    func reset() {
        executedCommands = []
        executedBatchCommands = []
        executedPrivilegedCommands = []
        batchCallCount = 0
        privilegedCallCount = 0
        shouldThrowError = nil
    }
}
