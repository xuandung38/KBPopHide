@testable import KSAPDismiss
import Foundation

final class MockFileSystem: FileSystemProtocol, @unchecked Sendable {
    var files: [String: Data] = [:]

    func fileExists(atPath path: String) -> Bool {
        files.keys.contains(path)
    }

    func contents(atPath path: String) -> Data? {
        files[path]
    }
}
