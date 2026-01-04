import Foundation

/// Protocol for USB keyboard monitoring abstraction
/// Enables dependency injection and testing of real-time USB monitoring behavior
protocol USBMonitorProtocol: AnyObject, Sendable {
    /// Whether monitoring is currently active
    var isMonitoring: Bool { get }

    /// Callback invoked when a keyboard is connected (vendorID, productID)
    var onKeyboardConnected: ((Int, Int) -> Void)? { get set }

    /// Start monitoring for USB keyboard connections
    func startMonitoring()

    /// Stop monitoring for USB keyboard connections
    func stopMonitoring()
}
