@testable import KSAPDismiss
import Foundation

/// Mock USB monitor for testing keyboard connection detection behavior
final class MockUSBMonitor: USBMonitorProtocol, @unchecked Sendable {
    private(set) var isMonitoring: Bool = false
    var onKeyboardConnected: ((Int, Int) -> Void)?

    // Test instrumentation
    private(set) var startMonitoringCallCount = 0
    private(set) var stopMonitoringCallCount = 0

    func startMonitoring() {
        startMonitoringCallCount += 1
        isMonitoring = true
    }

    func stopMonitoring() {
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
    }
}
