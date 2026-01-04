import Foundation

protocol USBDetectorProtocol: Sendable {
    static func detectConnectedKeyboards() -> [(vendorID: Int, productID: Int)]
}
