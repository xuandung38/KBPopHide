@testable import KSAPDismiss
import XCTest

/// Tests for USBMonitor protocol behavior via MockUSBMonitor
/// Tests real-time USB keyboard monitoring functionality
final class USBMonitorTests: XCTestCase {
    var mockMonitor: MockUSBMonitor!

    override func setUp() {
        super.setUp()
        mockMonitor = MockUSBMonitor()
    }

    override func tearDown() {
        mockMonitor.reset()
        mockMonitor = nil
        super.tearDown()
    }

    // MARK: - Monitoring State Tests

    func testInitialState() {
        XCTAssertFalse(mockMonitor.isMonitoring, "Monitor should not be active initially")
        XCTAssertEqual(mockMonitor.startMonitoringCallCount, 0)
        XCTAssertEqual(mockMonitor.stopMonitoringCallCount, 0)
    }

    func testStartMonitoring() {
        mockMonitor.startMonitoring()

        XCTAssertTrue(mockMonitor.isMonitoring, "Monitor should be active after start")
        XCTAssertEqual(mockMonitor.startMonitoringCallCount, 1)
    }

    func testStopMonitoring() {
        mockMonitor.startMonitoring()
        mockMonitor.stopMonitoring()

        XCTAssertFalse(mockMonitor.isMonitoring, "Monitor should be inactive after stop")
        XCTAssertEqual(mockMonitor.stopMonitoringCallCount, 1)
    }

    func testMultipleStartStopCycles() {
        // First cycle
        mockMonitor.startMonitoring()
        XCTAssertTrue(mockMonitor.isMonitoring)
        mockMonitor.stopMonitoring()
        XCTAssertFalse(mockMonitor.isMonitoring)

        // Second cycle
        mockMonitor.startMonitoring()
        XCTAssertTrue(mockMonitor.isMonitoring)
        mockMonitor.stopMonitoring()
        XCTAssertFalse(mockMonitor.isMonitoring)

        XCTAssertEqual(mockMonitor.startMonitoringCallCount, 2)
        XCTAssertEqual(mockMonitor.stopMonitoringCallCount, 2)
    }

    // MARK: - Callback Tests

    func testKeyboardConnectionCallback() {
        var receivedVendorID: Int?
        var receivedProductID: Int?
        var callbackCount = 0

        mockMonitor.onKeyboardConnected = { vendorID, productID in
            receivedVendorID = vendorID
            receivedProductID = productID
            callbackCount += 1
        }

        mockMonitor.simulateKeyboardConnection(vendorID: 1452, productID: 635)

        XCTAssertEqual(receivedVendorID, 1452, "Should receive correct vendor ID")
        XCTAssertEqual(receivedProductID, 635, "Should receive correct product ID")
        XCTAssertEqual(callbackCount, 1, "Callback should be invoked once")
    }

    func testMultipleKeyboardConnections() {
        var connections: [(vendorID: Int, productID: Int)] = []

        mockMonitor.onKeyboardConnected = { vendorID, productID in
            connections.append((vendorID, productID))
        }

        // Simulate multiple keyboard connections
        mockMonitor.simulateKeyboardConnection(vendorID: 1452, productID: 635)
        mockMonitor.simulateKeyboardConnection(vendorID: 1234, productID: 5678)
        mockMonitor.simulateKeyboardConnection(vendorID: 9999, productID: 1111)

        XCTAssertEqual(connections.count, 3, "Should record all connections")
        XCTAssertEqual(connections[0].vendorID, 1452)
        XCTAssertEqual(connections[1].vendorID, 1234)
        XCTAssertEqual(connections[2].vendorID, 9999)
    }

    func testCallbackNotInvokedWithoutHandler() {
        // No callback set - should not crash
        mockMonitor.simulateKeyboardConnection(vendorID: 1452, productID: 635)
        // Test passes if no crash occurs
    }

    // MARK: - Reset Tests

    func testReset() {
        var callbackInvoked = false
        mockMonitor.onKeyboardConnected = { _, _ in callbackInvoked = true }
        mockMonitor.startMonitoring()

        mockMonitor.reset()

        XCTAssertFalse(mockMonitor.isMonitoring, "Monitoring should be off after reset")
        XCTAssertEqual(mockMonitor.startMonitoringCallCount, 0, "Call count should reset")
        XCTAssertEqual(mockMonitor.stopMonitoringCallCount, 0, "Call count should reset")

        // Verify callback was cleared
        mockMonitor.simulateKeyboardConnection(vendorID: 1, productID: 1)
        XCTAssertFalse(callbackInvoked, "Callback should be cleared after reset")
    }

    // MARK: - Protocol Conformance Tests

    func testProtocolConformance() {
        let monitor: any USBMonitorProtocol = mockMonitor

        monitor.startMonitoring()
        XCTAssertTrue(monitor.isMonitoring)

        monitor.stopMonitoring()
        XCTAssertFalse(monitor.isMonitoring)
    }
}
