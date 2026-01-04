# Code Standards & Guidelines

## Swift Language Standards

### Style Guide

**Swift Version**: Swift 5.9+

**Naming Conventions**:
- **Types**: PascalCase (`class KeyboardManager`, `struct Keyboard`)
- **Functions/Methods**: camelCase (`func addKeyboardEntries()`, `var isConnected`)
- **Constants**: camelCase with `k` prefix for file-level constants (`let kHelperBundleID`, `let kHelperVersion`)
- **Enum Cases**: camelCase (`.notConnected`, `.connectionFailed`)
- **Argument Labels**: Include labels for clarity (`withReply`, `maxAttempts`)

**Line Length**: Max 120 characters (enforce via linter if available)

**Indentation**: 4 spaces (Swift convention)

**Braces**: Opening brace on same line (Swift convention)

```swift
// Correct
if condition {
    doSomething()
}

// Incorrect
if condition
{
    doSomething()
}
```

### Concurrency Model

**Default**: Use Swift async/await

```swift
// Correct
func connect() async throws {
    // Implementation
}

// Avoid (legacy)
func connect(completion: @escaping (Result<Void, Error>) -> Void) {
    // Implementation
}
```

**Thread Safety**:
- Use `@MainActor` for UI-related code
- Use `DispatchQueue` for background operations
- Use `Task` for creating concurrent work
- Avoid direct `DispatchQueue.main` unless necessary

```swift
// Correct
@MainActor
final class XPCClient: ObservableObject {
    @Published var isConnected = false

    private let connectionQueue = DispatchQueue(label: "com.hxd.ksapdismiss.xpc")

    func connect() async throws {
        try await withCheckedThrowingContinuation { continuation in
            connectionQueue.async { [weak self] in
                // Background work
                Task { @MainActor in
                    // UI updates
                }
            }
        }
    }
}
```

### Error Handling

**Prefer explicit error types**:

```swift
// Correct
enum XPCError: LocalizedError {
    case notConnected
    case connectionFailed
    case operationFailed(String)

    var errorDescription: String? {
        switch self {
        case .notConnected:
            return "Not connected to helper"
        case .connectionFailed:
            return "Failed to connect to helper. Please reinstall."
        case .operationFailed(let msg):
            return "Operation failed: \(msg)"
        }
    }
}

// Avoid
throw NSError(domain: "error", code: 1)
```

**Use Result type for protocol methods**:

```swift
// Correct for callbacks
func getVersion(withReply reply: @escaping (String) -> Void)
func addKeyboardEntries(
    _ entries: [[String: Any]],
    withReply reply: @escaping (Bool, String?) -> Void
)

// Avoid multiple completion handlers
func operation(onSuccess: @escaping () -> Void, onError: @escaping (Error) -> Void)
```

### Memory Management

**Capture Lists**:

```swift
// Correct - avoid retain cycles
handler { [weak self] in
    self?.doSomething()
}

// Also acceptable for small closures where retain cycle is acceptable
self.handler { in
    print("no self needed")
}
```

**Weak Self Checks**:

```swift
// Correct
handler { [weak self] in
    guard let self = self else { return }
    self.property = value
}

// Avoid
handler { [weak self] in
    self?.property = value  // OK if only one line
}
```

### Documentation

**All public APIs must have documentation**:

```swift
/// Establish connection to helper
///
/// Performs version check and validates protocol compatibility.
/// Updates `isConnected` and `helperVersion` on success.
///
/// - Throws: `XPCError.connectionFailed` if connection fails
/// - Note: Use `connectWithRetry()` for automatic retry logic
func connect() async throws {
    // Implementation
}
```

**Parameter Documentation**:

```swift
/// Add keyboard entries to plist
/// - Parameters:
///   - entries: Array of (identifier, type) tuples
///   - maxAttempts: Maximum number of retry attempts (default: 3)
/// - Returns: Success status
func addKeyboardEntries(
    _ entries: [(identifier: String, type: Int)],
    maxAttempts: Int = 3
) async throws {
    // Implementation
}
```

**Complex Logic Comments**:

```swift
// Explain "why", not "what"
// Retry with exponential backoff to handle transient connection issues
for attempt in 1...maxAttempts {
    do {
        try await connect()
        return
    } catch {
        // Exponential: 500ms * 2^(attempt-1)
        let delay = UInt64(500_000_000 * pow(2, Double(attempt - 1)))
        try await Task.sleep(nanoseconds: delay)
    }
}
```

## SwiftUI Component Standards

### View Structure

**Organize sections with MARK**:

```swift
struct SettingsView: View {
    // MARK: - Properties

    @StateObject var keyboardManager: KeyboardManager
    @Environment(\.dismiss) var dismiss

    // MARK: - Body

    var body: some View {
        VStack {
            // Content
        }
    }

    // MARK: - Private Views

    private var headerView: some View {
        // View implementation
    }

    // MARK: - Private Methods

    private func updateSettings() {
        // Implementation
    }
}
```

**State Management**:

```swift
// Correct - use StateObject for initialization
struct ContentView: View {
    @StateObject var keyboardManager = KeyboardManager()
    // Use throughout view tree
}

// Correct - use ObservedObject when passed in
struct ChildView: View {
    @ObservedObject var keyboardManager: KeyboardManager
    // Use the manager
}

// Avoid - not reactive to changes
struct BadView: View {
    let keyboardManager = KeyboardManager()
}
```

### View Modifiers

**Extract complex modifiers**:

```swift
// Correct
extension View {
    func primaryButtonStyle() -> some View {
        self.padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
    }
}

Button("Action") { }
    .primaryButtonStyle()

// Avoid - repeated code
Button("Action") { }
    .padding()
    .background(Color.blue)
    .foregroundColor(.white)
    .cornerRadius(8)
```

## Protocol & Abstraction Standards

### Protocol Design

**All external dependencies should be protocol-based**:

```swift
// Good - testable and flexible
protocol USBMonitorProtocol: AnyObject {
    var onKeyboardDetected: ((USBDevice) -> Void)? { get set }
    var onKeyboardRemoved: ((USBDevice) -> Void)? { get set }
}

class KeyboardManager {
    let usbMonitor: USBMonitorProtocol

    init(usbMonitor: USBMonitorProtocol = USBMonitor()) {
        self.usbMonitor = usbMonitor
    }
}

// Easy to test with mock
class MockUSBMonitor: USBMonitorProtocol {
    var onKeyboardDetected: ((USBDevice) -> Void)?
    var onKeyboardRemoved: ((USBDevice) -> Void)?
}
```

**XPC Protocol Design**:

```swift
// Correct - uses Objective-C for XPC marshalling
@objc(HelperProtocol)
protocol HelperProtocol {
    func getVersion(withReply reply: @escaping (String) -> Void)
    func addKeyboardEntries(
        _ entries: [[String: Any]],
        withReply reply: @escaping (Bool, String?) -> Void
    )
}

// Incorrect - Swift-only doesn't work with XPC
protocol HelperProtocol {
    func getVersion() async -> String
}
```

## Testing Standards

### Unit Test Structure

```swift
final class KeyboardManagerTests: XCTestCase {

    // MARK: - Setup & Teardown

    var sut: KeyboardManager!  // System Under Test
    var mockUSBMonitor: MockUSBMonitor!

    override func setUp() {
        super.setUp()
        mockUSBMonitor = MockUSBMonitor()
        sut = KeyboardManager(usbMonitor: mockUSBMonitor)
    }

    override func tearDown() {
        sut = nil
        mockUSBMonitor = nil
        super.tearDown()
    }

    // MARK: - Tests

    func testAddKeyboardsUpdatesState() {
        // Given
        let keyboards = [TestData.sampleKeyboard]

        // When
        sut.addKeyboards(keyboards)

        // Then
        XCTAssertTrue(sut.hasKeyboards)
        XCTAssertEqual(sut.keyboards.count, 1)
    }

    // MARK: - Async Tests

    @MainActor
    func testConnectUpdatesState() async {
        // Given
        let xpcClient = XPCClient.shared

        // When
        try? await xpcClient.connect()

        // Then
        XCTAssertTrue(xpcClient.isConnected)
    }
}
```

**Test Naming**:
- Pattern: `test<Subject><Scenario><ExpectedResult>`
- Examples:
  - `testAddKeyboardsUpdatesState`
  - `testXPCErrorDescriptions`
  - `testConnectWithRetryAttemptsThreeTimes`

**MainActor in Tests**:

```swift
@MainActor
func testMainActorIsolatedCode() {
    // Test code that requires MainActor
    XCTAssertFalse(XPCClient.shared.isConnected)
}
```

## Architecture Patterns

### Singleton Pattern

**Use for shared resources**:

```swift
// Correct
@MainActor
final class XPCClient: ObservableObject {
    static let shared = XPCClient()
    private init() {}
    // Implementation
}

// Usage
let client = XPCClient.shared
```

**Avoid for testability concerns** - use dependency injection where possible

### Observable Pattern

**Use ObservableObject for UI coordination**:

```swift
// Correct
@MainActor
final class KeyboardManager: ObservableObject {
    @Published var keyboards: [Keyboard] = []
    @Published var isLoading = false

    func addKeyboards(_ keyboards: [Keyboard]) {
        Task {
            isLoading = true
            defer { isLoading = false }
            // Perform operation
            self.keyboards = keyboards
        }
    }
}

// In View
struct ContentView: View {
    @StateObject var manager = KeyboardManager()

    var body: some View {
        if manager.isLoading {
            ProgressView()
        } else {
            List(manager.keyboards) { keyboard in
                Text(keyboard.name)
            }
        }
    }
}
```

### Dependency Injection

**Always use DI for testability**:

```swift
// Good
class KeyboardManager {
    let fileSystem: FileSystemProtocol
    let authHelper: AuthorizationProtocol

    init(
        fileSystem: FileSystemProtocol = FileSystem(),
        authHelper: AuthorizationProtocol = AuthorizationHelper()
    ) {
        self.fileSystem = fileSystem
        self.authHelper = authHelper
    }
}

// Test
let mockFS = MockFileSystem()
let mockAuth = MockAuthHelper()
let manager = KeyboardManager(fileSystem: mockFS, authHelper: mockAuth)
```

## XPC-Specific Standards

### Protocol Definition

```swift
// Correct
@objc(HelperProtocol)
protocol HelperProtocol {
    /// Method documentation
    func getVersion(withReply reply: @escaping (String) -> Void)

    /// Method documentation
    func addKeyboardEntries(
        _ entries: [[String: Any]],
        withReply reply: @escaping (Bool, String?) -> Void
    )
}

// Key points:
// 1. Must be @objc protocol (Objective-C runtime required)
// 2. All parameters must be Objective-C compatible
// 3. Use reply: callbacks (no async/await in XPC protocol)
// 4. Document all parameters and return values
```

### Client Implementation

```swift
// Correct pattern for XPC calls
private func getHelper() throws -> HelperProtocol {
    guard let connection = connection,
          let helper = connection.remoteObjectProxyWithErrorHandler({ _ in })
              as? HelperProtocol else {
        throw XPCError.notConnected
    }
    return helper
}

func addKeyboardEntries(_ entries: [(identifier: String, type: Int)]) async throws {
    let helper = try getHelper()

    let entriesDict = entries.map { entry in
        ["identifier": entry.identifier, "type": entry.type] as [String: Any]
    }

    logger.info("Adding \(entries.count) keyboard entries")

    return try await withCheckedThrowingContinuation { continuation in
        helper.addKeyboardEntries(entriesDict) { success, error in
            if success {
                continuation.resume()
            } else {
                continuation.resume(throwing: XPCError.operationFailed(error ?? "Unknown"))
            }
        }
    }
}
```

## Logging Standards

**Use os.log subsystem**:

```swift
import os.log

let logger = Logger(subsystem: "com.hxd.ksapdismiss", category: "XPCClient")

logger.info("Connecting to helper...")
logger.warning("Connection interrupted")
logger.error("XPC error: \(error.localizedDescription)")
```

**Subsystems** (consistent across app):
- Main app: `com.hxd.ksapdismiss`
- XPC module: `com.hxd.ksapdismiss`
- Helper: `com.hxd.ksapdismiss.helper`

**Log Levels**:
- `.debug`: Detailed debugging info (not in production logs)
- `.info`: Important state changes, operations
- `.warning`: Recoverable issues (retries, disconnections)
- `.error`: Failures that prevent operations

## File Organization

### Swift File Structure

Every Swift file should follow this structure:

```swift
import Foundation  // System imports first
import SwiftUI     // Framework imports
import os.log      // Apple framework imports

// MARK: - Main Class/Struct

/// Documentation
@MainActor
final class XPCClient: ObservableObject {
    // MARK: - Properties

    @Published private(set) var isConnected = false

    private var connection: NSXPCConnection?

    // MARK: - Lifecycle

    static let shared = XPCClient()
    private init() {}

    // MARK: - Public Methods

    func connect() async throws { }

    // MARK: - Private Methods

    private func getHelper() throws -> HelperProtocol { }
}

// MARK: - Extensions

extension XPCClient {
    var isHelperAvailable: Bool { }
}

// MARK: - Supporting Types

enum XPCError: LocalizedError {
    case notConnected
}
```

## Constants & Configuration

**File-Level Constants**:
- Prefix with `k` (e.g., `kHelperBundleID`)
- Place at top of file near imports
- Document purpose and update strategy

```swift
/// Helper bundle identifier constant
/// Must match InfoPlist and installer configuration
let kHelperBundleID = "com.hxd.ksapdismiss.helper"

/// Helper version - update when protocol changes
/// Update both client and helper together
let kHelperVersion = "1.0.0"
```

**Magic Numbers**:
Avoid magic numbers; define as constants:

```swift
// Avoid
let delay = 500_000_000  // What is this?

// Correct
let retryDelayNanoseconds: UInt64 = 500_000_000  // 500ms
let maxRetryAttempts = 3
```

## Performance Standards

**Optimize for readability first**, then performance

**Avoid**:
- Premature optimization
- Cryptic one-liners
- Complex nested closures

**Prefer**:
- Clear variable names
- Straightforward logic flow
- Comments for non-obvious code

## Authentication & Secure Operations Standards

### Biometric Authentication Patterns

**Always use SecureOperationExecutor for privileged operations**:

```swift
// Correct - Proper authentication flow
try await SecureOperationExecutor.shared.execute(
    reason: "Verify your identity to modify keyboard settings",
    operation: {
        try await performPrivilegedOperation()
    }
)

// Avoid - Accessing XPC directly without authentication
try await XPCClient.shared.removeAllKeyboardEntries()
```

**Provide meaningful authentication reasons**:

```swift
// Good - Describes what user is authorizing
try await SecureOperationExecutor.shared.removeAllKeyboardEntries()  // reason: "Reset keyboard settings"

// Bad - Too vague or too technical
try await SecureOperationExecutor.shared.removeAllKeyboardEntries()  // reason: "Operation"
```

### Error Handling in Authentication

**Check error properties before displaying**:

```swift
// Correct - Only show alerts for errors that should be visible
do {
    try await SecureOperationExecutor.shared.removeAllKeyboardEntries()
} catch let error as TouchIDError {
    if error.shouldShowAlert {
        showAlert(title: "Error", message: error.errorDescription ?? "")
    }
} catch {
    showAlert(title: "Error", message: error.localizedDescription)
}

// Avoid - Showing all errors as alerts (includes user cancellation)
} catch let error as TouchIDError {
    showAlert(error.errorDescription)  // Shows nil for userCanceled
}
```

**Use fallback properties to guide UI**:

```swift
// Correct - Offer retry path based on error type
catch let error as TouchIDError {
    if error.shouldFallbackToPassword {
        showButton("Try with Password") {
            retryWithFallback()
        }
    }
}

// Avoid - Same handling for all authentication errors
catch let error as TouchIDError {
    showAlert("Try again later")
}
```

### TouchIDAuthenticator Usage

**Check availability before showing biometric UI**:

```swift
// Correct - Only show biometric options if available
if TouchIDAuthenticator.shared.isBiometricAvailable {
    showBiometricOption(
        label: TouchIDAuthenticator.shared.biometricName
    )
}

// Avoid - Assuming biometrics are available
@MainActor
var biometricLabel: String {
    TouchIDAuthenticator.shared.biometricName  // Might show "Biometric" if unavailable
}
```

**Use authenticateWithFallback for sensitive operations**:

```swift
// Correct - Allows user flexibility for sensitive operations
try await TouchIDAuthenticator.shared.authenticateWithFallback(
    reason: "Authorize to disable Keyboard Setup Assistant"
)

// Consider - Use biometric-only for less sensitive operations
try await TouchIDAuthenticator.shared.authenticate(
    reason: "Verify identity"
)
```

### Task-Based Authentication Flow

**Wrap authentication in Task for UI updates**:

```swift
// Correct - Handles MainActor requirement
func deleteKeyboards() {
    Task {
        do {
            try await SecureOperationExecutor.shared
                .removeAllKeyboardEntries()
            await updateUI(success: true)
        } catch {
            await handleError(error)
        }
    }
}

// Correct - Use @MainActor on view methods
@MainActor
private func handleError(_ error: Error) {
    if let touchIDError = error as? TouchIDError {
        if touchIDError.shouldShowAlert {
            showAlert(touchIDError.errorDescription ?? "")
        }
    }
}

// Avoid - Blocking UI thread with authentication
func deleteKeyboards() {  // Not async
    // Can't call async authenticate()
}
```

### Testing Authentication Code

**Provide mock for authentication in tests**:

```swift
// Correct - Test without requiring actual biometric
final class KeyboardManagerTests: XCTestCase {
    override func setUp() {
        super.setUp()
        // Mock TouchIDAuthenticator behavior if needed
        // Tests should verify auth was attempted, not the actual biometric
    }

    func testRemoveKeyboardsRequiresAuth() {
        // Verify SecureOperationExecutor is called
        // Don't test actual LocalAuthentication
    }
}

// Avoid - Testing actual biometric in unit tests
func testBiometricPromptAppears() {
    // Can't reliably test UI prompts in unit tests
}
```

### Singleton Access Patterns

**Always use singleton references consistently**:

```swift
// Correct - Use .shared singleton
let executor = SecureOperationExecutor.shared
let authenticator = TouchIDAuthenticator.shared
let xpc = XPCClient.shared

// Avoid - Creating new instances
let executor = SecureOperationExecutor()  // Creates duplicate!
```

**Capture by reference in closures**:

```swift
// Correct - Self is captured, authenticator changes reflected
Task { @MainActor in
    if TouchIDAuthenticator.shared.isBiometricAvailable {
        updateUI()
    }
}

// OK - Capture once if used repeatedly in closure
let isBioAvailable = TouchIDAuthenticator.shared.isBiometricAvailable
Task { @MainActor in
    if isBioAvailable {
        updateUI()
    }
}
```

### Configuration & Entitlements

**Document required entitlements in code comments**:

```swift
// IMPORTANT: Requires entitlements:
// - com.apple.security.device.local-authentication = true
// See: KSAPDismiss/KSAPDismiss.entitlements
@MainActor
final class TouchIDAuthenticator: ObservableObject {
    // Implementation
}
```

**Update both Info.plist and entitlements**:

```swift
// When adding Face ID support:
// 1. Update KSAPDismiss.entitlements
// 2. Add NSFaceIDUsageDescription to Info.plist
// 3. Document in authentication-guide.md
```

## Deprecation & Migration

**Deprecate carefully**:

```swift
@available(*, deprecated, message: "Use XPCClient.shared instead. Will be removed in v2.0")
func authorizeOperation() -> Bool {
    // Old implementation using AuthorizationHelper
}
```

**Migration Timeline**:
1. Deprecate in current version
2. Maintain 2-3 major versions
3. Remove completely only when safe

## Code Review Checklist

Before submitting PR, verify:

- [ ] Follows naming conventions
- [ ] Uses async/await (not callbacks)
- [ ] Has proper error handling
- [ ] Includes documentation for public APIs
- [ ] Uses MainActor where appropriate
- [ ] No retain cycles (weak self where needed)
- [ ] Tests added for new functionality
- [ ] No console warnings/errors when running
- [ ] Logs at appropriate levels
- [ ] No hardcoded values (use constants)
- [ ] Follows MARK section organization
- [ ] Proper access control (private, fileprivate)

## Helper Installation Standards (Phase 4)

### HelperInstaller Usage Patterns

**Always use HelperInstaller.shared for installation**:

```swift
// Correct - Use singleton
let installer = HelperInstaller.shared

// Check status
if !installer.isInstalled {
    try await installer.install()
}

// Install if needed (preferred)
let wasInstalled = try await installer.installIfNeeded()

// Avoid - Creating new instances
let installer = HelperInstaller()  // Creates duplicate!
```

**Check installation before XPC operations**:

```swift
// Correct - Ensures helper exists before connection
if !HelperInstaller.shared.isInstalled {
    try await HelperInstaller.shared.install()
}
try await XPCClient.shared.connect()

// Avoid - Assumes helper is installed
try await XPCClient.shared.connect()  // May fail if helper missing
```

**Handle installation errors gracefully**:

```swift
// Correct - Distinguish between error types
do {
    try await HelperInstaller.shared.install()
} catch let error as HelperInstallerError {
    switch error {
    case .userCanceled:
        // User can retry
        showRetryButton()
    case .authorizationDenied:
        // Requires admin rights
        showAdminRequiredMessage()
    case .blessFailed(let msg):
        // SMJobBless failed
        logger.error("Helper installation failed: \(msg ?? "unknown")")
    default:
        // Other installation errors
        break
    }
} catch {
    // Unexpected error
}

// Avoid - Generic error handling
} catch {
    showAlert("Installation failed")
}
```

**Monitor installation state in UI**:

```swift
// Correct - Observe published properties
struct ContentView: View {
    @StateObject var installer = HelperInstaller.shared

    var body: some View {
        if installer.isInstalling {
            ProgressView("Installing helper...")
        } else if installer.isInstalled {
            Text("Helper installed: v\(installer.installedVersion ?? "unknown")")
        } else {
            Button("Install Helper") {
                Task {
                    try? await installer.install()
                }
            }
        }
    }
}

// Avoid - Assuming state without observation
Text("Helper status: \(HelperInstaller.shared.isInstalled ? "installed" : "not installed")")
// Text won't update when isInstalled changes
```

**Version compatibility checking**:

```swift
// Correct - Check version after installation
try await HelperInstaller.shared.install()
if installer.isInstalled {
    let version = installer.installedVersion
    if version != kHelperVersion {
        logger.warning("Helper version mismatch: \(version ?? "unknown") vs \(kHelperVersion)")
    }
}

// Avoid - Assuming version match
try await HelperInstaller.shared.install()
try await XPCClient.shared.connect()  // May have protocol mismatch
```

### SMJobBless Best Practices

**Authorization Flow**:

1. User initiates privileged operation
2. Create AuthorizationRef (created by HelperInstaller)
3. Request SMJobBless right
4. Show authorization prompt (user enters admin password)
5. Call SMJobBless() on background queue
6. Verify installation success
7. Clear authorization reference

```swift
// Implementation pattern in HelperInstaller
var status = AuthorizationCreate(nil, nil, [], &authRef)

// Request right with user interaction
status = AuthorizationCopyRights(
    auth,
    &rights,
    nil,
    [.interactionAllowed, .extendRights, .preAuthorize],
    nil
)

// Bless the helper
let success = SMJobBless(
    kSMDomainSystemLaunchd,
    helperBundleID as CFString,
    auth,
    &cfError
)

// Clean up
AuthorizationFree(auth, [])
```

**Configuration Requirements**:

1. **Helper Entitlements** must disable sandboxing:
```xml
<key>com.apple.security.app-sandbox</key>
<false/>
```

2. **Launchd Plist** must be in bundle:
```
Helper/launchd.plist → /Library/LaunchDaemons/com.hxd.ksapdismiss.helper.plist
```

3. **Main App Info.plist** must register helper:
```
SMPrivilegedExecutables: {
    "com.hxd.ksapdismiss.helper": "<code-signing-requirement>"
}
```

### Installation Lifecycle

**Initialization**:
- `HelperInstaller.shared` checks status in `init()`
- Sets `isInstalled` and `installedVersion` properties
- Subscribes to system notifications (future)

**Installation**:
- User initiates operation via UI
- `SecureOperationExecutor.execute()` checks `installer.isInstalled`
- Calls `installer.install()` if needed
- Sets `isInstalling = true` during process
- Shows authorization prompt to user
- Updates `isInstalled` and `installedVersion` on success
- Sets `isInstalling = false` when complete

**Uninstallation**:
- Remove helper binary from `/Library/PrivilegedHelperTools/`
- Remove launchd plist from `/Library/LaunchDaemons/`
- Update `isInstalled` property
- Clear `installedVersion`

### Testing HelperInstaller

**Unit Tests**:
```swift
@MainActor
func testHelperInstallerSingleton() {
    let installer1 = HelperInstaller.shared
    let installer2 = HelperInstaller.shared
    XCTAssertTrue(installer1 === installer2)
}

@MainActor
func testInstallationStateTracking() {
    let installer = HelperInstaller.shared
    XCTAssertFalse(installer.isInstalling)
}

func testErrorDescriptions() {
    let errors: [HelperInstallerError] = [
        .authorizationDenied,
        .userCanceled,
        .blessFailed("test")
    ]
    for error in errors {
        XCTAssertNotNil(error.errorDescription)
    }
}
```

**Integration Tests** (require admin privileges):
- Test actual SMJobBless installation
- Verify launchd registration
- Confirm XPC connection after installation
- Test version checking
- Test update detection

## References

- [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- [SwiftUI Best Practices](https://developer.apple.com/documentation/swiftui/)
- [Concurrency Documentation](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html)
- [XPC Programming Guide](https://developer.apple.com/documentation/xpc/)
- [SMJobBless Framework](https://developer.apple.com/documentation/servicemanagement/smjobbless)
- [Authorization Services Programming Guide](https://developer.apple.com/library/archive/documentation/Security/Conceptual/Authorization_Concepts/01introduction/introduction.html)
- [Launchd Documentation](https://www.manpagez.com/man/8/launchd/)

## Document Metadata

- **Last Updated**: 2026-01-04
- **Swift Version**: 5.9+
- **Enforced By**: Code review, pull request checks
- **Status**: Active standards for Phase 4 and beyond
- **Coverage**: Foundation, XPC Communication, Authentication & Secure Operations, Helper Installation
