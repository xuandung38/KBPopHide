@testable import KSAPDismiss
import Foundation

/// Mock USB monitor for testing keyboard connection detection behavior
@MainActor
final class MockUSBMonitor: USBMonitorProtocol, @unchecked Sendable {
    private(set) var isMonitoring: Bool = false
    var onKeyboardConnected: ((Int, Int) -> Void)?

    // Test instrumentation
    private(set) var startMonitoringCallCount = 0
    private(set) var stopMonitoringCallCount = 0

    // Internal flag for synchronous test updates
    nonisolated(unsafe) private var pendingStart = false
    nonisolated(unsafe) private var pendingStop = false

    nonisolated func startMonitoring() {
        pendingStart = true
    }

    nonisolated func stopMonitoring() {
        pendingStop = true
    }

    /// Process pending state changes (call from MainActor context in tests)
    func processPendingChanges() {
        if pendingStart {
            startMonitoringCallCount += 1
            isMonitoring = true
            pendingStart = false
        }
        if pendingStop {
            stopMonitoringCallCount += 1
            isMonitoring = false
            pendingStop = false
        }
    }

    /// Start monitoring synchronously for testing
    func startMonitoringSync() {
        startMonitoringCallCount += 1
        isMonitoring = true
    }

    /// Stop monitoring synchronously for testing
    func stopMonitoringSync() {
        stopMonitoringCallCount += 1
        isMonitoring = false
    }

    /// Simulate a keyboard connection event for testing
    func simulateKeyboardConnection(vendorID: Int, productID: Int) {
        onKeyboardConnected?(vendorID, productID)
    }

    /// Reset mock state for test isolation
    func reset() {
        isMonitoring = false
        onKeyboardConnected = nil
        startMonitoringCallCount = 0
        stopMonitoringCallCount = 0
        pendingStart = false
        pendingStop = false
    }
}
