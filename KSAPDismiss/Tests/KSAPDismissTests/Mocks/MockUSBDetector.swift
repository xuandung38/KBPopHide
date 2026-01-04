@testable import KSAPDismiss
import Foundation

final class MockUSBDetector: USBDetectorProtocol, @unchecked Sendable {
    static var detectedKeyboards: [(vendorID: Int, productID: Int)] = []

    static func detectConnectedKeyboards() -> [(vendorID: Int, productID: Int)] {
        return detectedKeyboards
    }
}
