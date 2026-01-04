import Foundation
import IOKit
import IOKit.usb
import IOKit.hid

/// Real-time USB keyboard monitoring using IOKit notifications
@MainActor
final class USBMonitor: ObservableObject, @preconcurrency USBMonitorProtocol, @unchecked Sendable {
    static let shared = USBMonitor()

    @Published private(set) var isMonitoring = false

    // IOKit resources - nonisolated for background thread access
    nonisolated(unsafe) private var notifyPort: IONotificationPortRef?
    nonisolated(unsafe) private var addedIterator: io_iterator_t = 0
    nonisolated(unsafe) private var runLoopSource: CFRunLoopSource?
    private let monitorQueue = DispatchQueue(label: "com.KSAPDismiss.usbmonitor", qos: .utility)

    /// Callback when new keyboard is connected (vendorID, productID)
    var onKeyboardConnected: ((Int, Int) -> Void)?

    private init() {}

    /// Start monitoring for USB keyboard connections
    nonisolated func startMonitoring() {
        monitorQueue.async { [weak self] in
            self?.setupMonitoring()
        }
    }

    /// Stop monitoring for USB keyboard connections
    nonisolated func stopMonitoring() {
        monitorQueue.async { [weak self] in
            self?.teardownMonitoring()
        }
    }

    private nonisolated func setupMonitoring() {
        // Create matching dictionary for USB devices
        guard let matchingDict = IOServiceMatching(kIOUSBDeviceClassName) else {
            print("USBMonitor: Failed to create matching dictionary")
            return
        }

        // Create notification port
        let port = IONotificationPortCreate(kIOMainPortDefault)
        guard let port = port else {
            print("USBMonitor: Failed to create notification port")
            return
        }

        // Schedule on main run loop
        let source = IONotificationPortGetRunLoopSource(port).takeUnretainedValue()
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .defaultMode)

        // Setup callback context
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        // Add matching notification for device arrival
        var iterator: io_iterator_t = 0
        let result = IOServiceAddMatchingNotification(
            port,
            kIOMatchedNotification,
            matchingDict,
            usbDeviceAdded,
            selfPtr,
            &iterator
        )

        guard result == KERN_SUCCESS else {
            print("USBMonitor: Failed to add matching notification: \(result)")
            IONotificationPortDestroy(port)
            return
        }

        // Store references for cleanup
        self.notifyPort = port
        self.runLoopSource = source
        self.addedIterator = iterator

        // Drain existing devices (required by IOKit to arm the notification)
        self.drainIterator(iterator)

        // Update state on main actor
        Task { @MainActor [weak self] in
            self?.isMonitoring = true
        }
    }

    private nonisolated func teardownMonitoring() {
        // Remove run loop source first
        if let source = self.runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .defaultMode)
            self.runLoopSource = nil
        }

        // Release iterator
        if self.addedIterator != 0 {
            IOObjectRelease(self.addedIterator)
            self.addedIterator = 0
        }

        // Destroy notification port
        if let port = self.notifyPort {
            IONotificationPortDestroy(port)
            self.notifyPort = nil
        }

        // Update state on main actor
        Task { @MainActor [weak self] in
            self?.isMonitoring = false
        }
    }

    private nonisolated func drainIterator(_ iterator: io_iterator_t) {
        while case let device = IOIteratorNext(iterator), device != 0 {
            IOObjectRelease(device)
        }
    }

    /// Process newly connected device
    nonisolated func processDevice(_ device: io_object_t) {
        defer { IOObjectRelease(device) }

        // Get device name to check if it's a keyboard
        var nameBuffer = [CChar](repeating: 0, count: 128)
        IORegistryEntryGetName(device, &nameBuffer)
        let deviceName = String(cString: nameBuffer).lowercased()

        // Get vendor ID
        var vendorID: Int = 0
        if let vendorRef = IORegistryEntryCreateCFProperty(device, kUSBVendorID as CFString, kCFAllocatorDefault, 0) {
            vendorID = (vendorRef.takeRetainedValue() as? NSNumber)?.intValue ?? 0
        }

        // Get product ID
        var productID: Int = 0
        if let productRef = IORegistryEntryCreateCFProperty(device, kUSBProductID as CFString, kCFAllocatorDefault, 0) {
            productID = (productRef.takeRetainedValue() as? NSNumber)?.intValue ?? 0
        }

        // Check if device is a keyboard (by name or interface class)
        let isKeyboard = deviceName.contains("keyboard") || checkIfKeyboardInterface(device)

        if isKeyboard && vendorID > 0 && productID > 0 {
            Task { @MainActor [weak self] in
                self?.onKeyboardConnected?(vendorID, productID)
            }
        }
    }

    /// Check device interfaces for HID keyboard class
    private nonisolated func checkIfKeyboardInterface(_ device: io_object_t) -> Bool {
        var iterator: io_iterator_t = 0

        // Get child iterator to check interfaces
        let result = IORegistryEntryGetChildIterator(device, kIOServicePlane, &iterator)
        guard result == KERN_SUCCESS else { return false }
        defer { IOObjectRelease(iterator) }

        while case let child = IOIteratorNext(iterator), child != 0 {
            defer { IOObjectRelease(child) }

            // Check interface class
            if let classRef = IORegistryEntryCreateCFProperty(child, kUSBInterfaceClass as CFString, kCFAllocatorDefault, 0) {
                let interfaceClass = (classRef.takeRetainedValue() as? NSNumber)?.intValue ?? 0
                // HID class = 3
                if interfaceClass == 3 {
                    // Check subclass for keyboard (1 = boot interface, protocol 1 = keyboard)
                    if let protocolRef = IORegistryEntryCreateCFProperty(child, kUSBInterfaceProtocol as CFString, kCFAllocatorDefault, 0) {
                        let interfaceProtocol = (protocolRef.takeRetainedValue() as? NSNumber)?.intValue ?? 0
                        if interfaceProtocol == 1 { // Keyboard protocol
                            return true
                        }
                    }
                }
            }
        }

        return false
    }
}

// C callback for IOKit notification
private func usbDeviceAdded(refCon: UnsafeMutableRawPointer?, iterator: io_iterator_t) {
    guard let refCon = refCon else { return }
    let monitor = Unmanaged<USBMonitor>.fromOpaque(refCon).takeUnretainedValue()

    // Process devices on background queue to avoid blocking callback
    DispatchQueue.global(qos: .utility).async {
        while case let device = IOIteratorNext(iterator), device != 0 {
            monitor.processDevice(device)
        }
    }
}
