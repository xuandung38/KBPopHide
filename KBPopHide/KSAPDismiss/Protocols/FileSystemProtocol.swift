import Foundation

protocol FileSystemProtocol: Sendable {
    func fileExists(atPath path: String) -> Bool
    func contents(atPath path: String) -> Data?
}

// Default implementation using FileManager
struct DefaultFileSystem: FileSystemProtocol {
    func fileExists(atPath path: String) -> Bool {
        FileManager.default.fileExists(atPath: path)
    }

    func contents(atPath path: String) -> Data? {
        FileManager.default.contents(atPath: path)
    }
}
