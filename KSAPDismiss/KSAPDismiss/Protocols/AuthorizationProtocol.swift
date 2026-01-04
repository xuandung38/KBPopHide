import Foundation

protocol AuthorizationProtocol: Sendable {
    func executeBatchShellCommand(_ shellCommand: String) throws
    func executePrivileged(command: String, args: [String]) throws
}

extension AuthorizationHelper: AuthorizationProtocol {}
