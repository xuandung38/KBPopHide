# System Architecture - Authentication & XPC Communication

## Overview

KSAP Dismiss implements a multi-layer security architecture combining biometric authentication with XPC (Inter-Process Communication). The system ensures that privileged operations (modifying keyboard preference files) require explicit user authorization via Touch ID/Face ID before being executed through a privileged helper tool. This design implements the principle of least privilege while providing a seamless user experience.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    Main Application                         │
│                  (KSAPDismiss.app)                          │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │      SecureOperationExecutor (Singleton)             │  │
│  │  Orchestrates authentication + XPC operations       │  │
│  │  ┌──────────────────────────────────────────────┐   │  │
│  │  │ Authentication Layer                         │   │  │
│  │  │ - Touch ID / Face ID verification            │   │  │
│  │  │ - Fallback to device passcode                │   │  │
│  │  │ - Error handling (lockout, enrollment)       │   │  │
│  │  └──────────────────────────────────────────────┘   │  │
│  │  ┌──────────────────────────────────────────────┐   │  │
│  │  │ Operation Execution                          │   │  │
│  │  │ - Execute after auth succeeds                │   │  │
│  │  │ - Handle auth failures gracefully            │   │  │
│  │  │ - Return operation results                   │   │  │
│  │  └──────────────────────────────────────────────┘   │  │
│  └──────────────────────────────────────────────────────┘  │
│                             │                               │
│  ┌──────────────────────────┴───────────────────────────┐  │
│  │     TouchIDAuthenticator (Singleton)                │  │
│  │  ┌──────────────────────────────────────────────┐   │  │
│  │  │ LocalAuthentication Framework                │   │  │
│  │  │ - Check biometric availability               │   │  │
│  │  │ - Authenticate with Touch ID only            │   │  │
│  │  │ - Authenticate with fallback to passcode    │   │  │
│  │  │ - Handle LAError mapping                     │   │  │
│  │  └──────────────────────────────────────────────┘   │  │
│  │  ┌──────────────────────────────────────────────┐   │  │
│  │  │ XPC Operation Layer                          │   │  │
│  │  │ - addKeyboardEntries()                       │   │  │
│  │  │ - removeAllKeyboardEntries()                 │   │  │
│  │  │ - getKeyboardStatus()                        │   │  │
│  │  └──────────────────────────────────────────────┘   │  │
│  └──────────────────────────────────────────────────────┘  │
│                             │                               │
│  ┌──────────────────────────┴───────────────────────────┐  │
│  │              XPCClient (Singleton)                   │  │
│  │  ┌──────────────────────────────────────────────┐   │  │
│  │  │ Connection Management                        │   │  │
│  │  │ - establish/disconnect to helper            │   │  │
│  │  │ - handle interruptions & invalidation       │   │  │
│  │  │ - version compatibility check               │   │  │
│  │  └──────────────────────────────────────────────┘   │  │
│  │  ┌──────────────────────────────────────────────┐   │  │
│  │  │ Resilience Features                         │   │  │
│  │  │ - auto-reconnect on failure                 │   │  │
│  │  │ - retry with exponential backoff            │   │  │
│  │  │ - connection state publishing               │   │  │
│  │  └──────────────────────────────────────────────┘   │  │
│  └──────────────────────────────────────────────────────┘  │
└────────────────────────────┬───────────────────────────────┘
                             │ NSXPCConnection
                             │ (machServiceName)
                             │
┌────────────────────────────┴───────────────────────────────┐
│          Privileged Helper Tool                            │
│      (/Library/PrivilegedHelperTools/)                     │
│      (com.hxd.ksapdismiss.helper)                          │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │           HelperProtocol Implementation             │  │
│  │  ┌──────────────────────────────────────────────┐   │  │
│  │  │ System Operations                           │   │  │
│  │  │ - plist file manipulation                   │   │  │
│  │  │ - keyboard entry management                 │   │  │
│  │  │ - file I/O with elevated privileges        │   │  │
│  │  └──────────────────────────────────────────────┘   │  │
│  │  ┌──────────────────────────────────────────────┐   │  │
│  │  │ KeyboardPlistManager                        │   │  │
│  │  │ - read/write to plist                       │   │  │
│  │  │ - validate entries                          │   │  │
│  │  │ - atomic operations                         │   │  │
│  │  └──────────────────────────────────────────────┘   │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                             │
│  Accessed File:                                            │
│  /Library/Preferences/com.apple.keyboardtype.plist        │
└─────────────────────────────────────────────────────────────┘
```

## Component Overview

### 1. SecureOperationExecutor (Main App - `Auth/SecureOperationExecutor.swift`)

**Type**: `@MainActor` Singleton

**Purpose**: Orchestrates biometric authentication with XPC operations. Ensures privileged operations only execute after successful user authentication.

**Responsibilities**:
- Coordinate Touch ID/Face ID authentication
- Manage authentication fallback to device passcode
- Execute privileged operations after authentication
- Handle authentication-related errors gracefully

**Key Properties**:
- `touchID`: Reference to TouchIDAuthenticator singleton
- `xpc`: Reference to XPCClient singleton

**Public Methods**:
```swift
// Generic secure operation execution
func execute<T>(
    reason: String,
    operation: @escaping () async throws -> T
) async throws -> T

// Keyboard-specific operations (convenience)
func addKeyboardEntries(_ entries: [(identifier: String, type: Int)]) async throws
func removeAllKeyboardEntries() async throws
func getKeyboardStatus() async throws -> (hasEntries: Bool, keyboards: [String]?)
```

**Execution Flow**:
1. User initiates operation
2. SecureOperationExecutor prompts for Touch ID authentication
3. On failure with fallback conditions (lockout, enrollment), attempts passcode fallback
4. After successful authentication, ensures XPC connection
5. Executes the provided operation
6. Returns operation result to caller

**Error Handling**:
- Automatically handles `TouchIDError.shouldFallbackToPassword` cases
- Propagates authentication failures to caller
- Ensures clean XPC state on operation completion

### 2. TouchIDAuthenticator (Main App - `Auth/TouchIDAuthenticator.swift`)

**Type**: `@MainActor` Singleton using `ObservableObject`

**Framework**: LocalAuthentication (LAContext)

**Purpose**: Wrapper around Apple's biometric authentication APIs with error mapping and fallback support.

**Responsibilities**:
- Check biometric availability on device
- Identify biometric type (Touch ID, Face ID, Optic ID)
- Execute biometric authentication
- Provide fallback authentication via device passcode
- Map LocalAuthentication errors to application-specific errors

**Key Properties**:
```swift
@Published var isBiometricAvailable: Bool
@Published var biometricType: LABiometryType
var biometricName: String  // Human-readable name (Touch ID, Face ID, etc.)
```

**Public Methods**:
```swift
// Check availability
func checkBiometricAvailability()

// Authentication
func authenticate(reason: String) async throws
func authenticateWithFallback(reason: String) async throws
```

**Authentication Modes**:
1. **Biometric Only**: Uses `.deviceOwnerAuthenticationWithBiometrics`
   - Touch ID on supported Macs
   - Face ID on supported Macs
   - Fails if biometric enrollment missing

2. **With Fallback**: Uses `.deviceOwnerAuthentication`
   - Attempts biometric first
   - Falls back to device passcode automatically
   - Recommended for sensitive operations

**Error Mapping**:
- `LAError.userCancel` → `TouchIDError.userCanceled`
- `LAError.userFallback` → `TouchIDError.userFallback`
- `LAError.biometryNotEnrolled` → `TouchIDError.notEnrolled`
- `LAError.biometryLockout` → `TouchIDError.lockout`
- `LAError.authenticationFailed` → `TouchIDError.failed`

**TouchIDError Cases**:
```swift
enum TouchIDError: LocalizedError {
    case notAvailable(String?)     // Hardware unavailable
    case notEnrolled               // No biometric data enrolled
    case lockout                   // Too many failed attempts
    case userCanceled              // User dismissed prompt
    case userFallback              // User requested password
    case failed                    // Authentication failed
    case unknown(String)           // Unmapped error

    // Properties for UI handling
    var shouldFallbackToPassword: Bool
    var shouldShowAlert: Bool
}
```

**Configuration**:
- Entitlement required: `com.apple.security.device.local-authentication` = true
- Info.plist key: `NSFaceIDUsageDescription` (for Face ID prompt authorization)
- Subsystem: "com.hxd.ksapdismiss", category: "TouchID"

### 3. XPCClient (Main App - `XPC/XPCClient.swift`)

**Type**: `@MainActor` Singleton using `ObservableObject`

**Responsibilities**:
- Establish/manage XPC connection to helper
- Provide async/await interface for helper operations
- Handle connection lifecycle (connect, disconnect, interruption)
- Implement retry logic and auto-reconnection
- Publish connection state to SwiftUI views

**Key Properties**:
- `isConnected`: Published boolean for UI binding
- `helperVersion`: Published version string for compatibility checks
- `connection`: Private NSXPCConnection instance
- `connectionQueue`: Dedicated DispatchQueue for thread safety

**Public Methods**:
```swift
// Connection management
func connect() async throws
func disconnect()
func connectWithRetry(maxAttempts: Int = 3) async throws

// Helper operations
func addKeyboardEntries(_ entries: [(identifier: String, type: Int)]) async throws
func removeAllKeyboardEntries() async throws
func getKeyboardStatus() async throws -> (hasEntries: Bool, keyboards: [String]?)

// Convenience methods
func withConnection<T>(_ operation: () async throws -> T) async throws -> T
var isHelperAvailable: Bool
func checkVersionCompatibility() -> Bool
```

### 4. HelperProtocol (XPC Interface - `XPC/HelperProtocol.swift`)

**Type**: `@objc` protocol (Objective-C runtime required for XPC)

**Purpose**: Defines the XPC service interface - shared contract between main app and helper

**Protocol Methods**:
```swift
@objc(HelperProtocol)
protocol HelperProtocol {
    // Get helper version for compatibility
    func getVersion(withReply: @escaping (String) -> Void)

    // Add keyboard entries to plist
    func addKeyboardEntries(
        _ entries: [[String: Any]],
        withReply: @escaping (Bool, String?) -> Void
    )

    // Remove all keyboard entries (enable KSA)
    func removeAllKeyboardEntries(
        withReply: @escaping (Bool, String?) -> Void
    )

    // Check if plist exists and has entries
    func getKeyboardStatus(
        withReply: @escaping (Bool, [String]?) -> Void
    )
}
```

**Constants**:
- `kHelperBundleID`: "com.hxd.ksapdismiss.helper"
- `kHelperVersion`: "1.0.0" (update when protocol changes)

### 5. Error Handling

**Error Types**:

#### TouchIDError (Authentication Layer)
```swift
enum TouchIDError: LocalizedError {
    case notAvailable(String?)
    case notEnrolled
    case lockout
    case userCanceled
    case userFallback
    case failed
    case unknown(String)
}
```

**Key Properties**:
- `shouldFallbackToPassword`: Indicates if user should be offered password fallback
- `shouldShowAlert`: Determines if error should be displayed to user

#### XPCError (Communication Layer)
```swift
enum XPCError: LocalizedError {
    case notConnected
    case connectionFailed
    case operationFailed(String)
    case helperNotInstalled
}
```

**Error Cases**:
- `.notConnected`: Client not connected to helper
- `.connectionFailed`: Failed to establish connection
- `.operationFailed(String)`: Helper operation failed
- `.helperNotInstalled`: Helper tool not found at standard location

## Connection Lifecycle

### 1. Connection Establishment

```
1. Call XPCClient.connect()
2. Create NSXPCConnection with:
   - machServiceName: "com.hxd.ksapdismiss.helper"
   - options: .privileged
3. Set remoteObjectInterface to HelperProtocol
4. Register handlers:
   - invalidationHandler: cleanup on disconnect
   - interruptionHandler: mark disconnected
5. Call conn.resume()
6. Verify connection by calling getVersion()
7. Update @Published properties on MainActor
8. Resume async/await continuation
```

### 2. Connection Usage

```
1. Client calls operation (e.g., addKeyboardEntries)
2. Get remoteObjectProxy as HelperProtocol
3. Call protocol method with reply handler
4. Helper executes privileged operation
5. Reply handler receives result on client
6. Continuation resumes with success/error
```

### 3. Connection Cleanup

```
1. Call XPCClient.disconnect()
2. connection.invalidate()
3. Update @Published properties
4. Clear references
```

## Auto-Reconnection Logic

### Retry Mechanism
- **Max Attempts**: 3 (configurable)
- **Backoff**: 500ms between attempts
- **Error Propagation**: Last error thrown if all attempts fail

### Auto-Connect on Operation
- Method: `withConnection<T>(_ operation:) async throws -> T`
- Automatically connects if not connected
- Single reconnect attempt on `.notConnected` error
- Useful for long-running apps where connection may be lost

## Thread Safety

**Design**:
- All UI updates happen on `@MainActor`
- Connection operations use dedicated `connectionQueue`
- NSXPCConnection is thread-safe (Apple's design)
- Closures capture `[weak self]` to prevent retain cycles

**DispatchQueue Usage**:
```swift
connectionQueue.async { [weak self] in
    // XPC connection setup
    Task { @MainActor in
        // UI updates
    }
}
```

## Testing Strategy

**Unit Tests** (`Tests/KSAPDismissTests/Unit/XPCClientTests.swift`):
- Error descriptions validation
- Protocol constants verification
- Singleton pattern verification
- Initial state validation
- Helper availability checks
- Version compatibility checks

**Note**: Full integration tests require:
- Installed helper tool
- Proper code signing
- Running in secure sandbox
- macOS authorization framework

## Security Considerations

### Privilege Elevation
- Uses XPC's `.privileged` option for helper tool communication
- Helper runs with elevated privileges (requires installer)
- Main app runs as unprivileged user

### Communication Channel
- XPC uses Mach IPC (kernel-level secure channel)
- No network exposure
- Only communicates with helper on same system

### Bundle Identifier Validation
- Helper bundle ID: `com.hxd.ksapdismiss.helper`
- Must match in installer and client code
- Update both if identifier changes

### Data Validation
- Helper validates all received entries
- Entries format: `["identifier": String, "type": Int]`
- Reply handlers check success flag

## Version Compatibility

**Purpose**: Ensure main app and helper speak same protocol

**Current Version**: 1.0.0

**Compatibility Check**:
```swift
func checkVersionCompatibility() -> Bool {
    guard let version = helperVersion else { return false }
    return version == kHelperVersion
}
```

**Versioning Strategy**:
- Update `kHelperVersion` when protocol changes
- Connect checks version via `getVersion()`
- Incompatible versions: throw `.connectionFailed`
- May support version-specific behavior in future

## Integration Points

### KeyboardManager
- Uses `XPCClient.shared` to execute operations
- Calls via `withConnection()` for auto-reconnect

### AppSettings
- Manages user preferences
- Coordinates with XPC operations

### UI Views
- Observe `XPCClient.isConnected` via `@StateObject`
- Display connection status to user
- Handle connection errors gracefully

## Logging

**Logger**: `os.log` subsystem "com.hxd.ksapdismiss", category "XPCClient"

**Log Levels**:
- `.info`: Connection established, operations started
- `.warning`: Connection lost, reconnection attempts
- `.error`: XPC communication errors

**Useful for**:
- Debugging connection issues
- Monitoring app health
- System log aggregation

## Phase 4: Helper Installation & Management

### HelperInstaller Component (Main App - `XPC/HelperInstaller.swift`)

**Type**: `@MainActor` Singleton using `ObservableObject`

**Framework**: ServiceManagement (SMJobBless), Security Framework

**Purpose**: Manages privileged helper tool installation, updates, and lifecycle using Apple's SMJobBless framework.

**Responsibilities**:
- Check if helper is installed at standard location
- Determine if helper updates are needed
- Install/update helper via SMJobBless with user authorization
- Uninstall helper tool
- Track installation state and progress

**Key Properties**:
```swift
@Published var isInstalled: Bool          // Helper binary exists
@Published var installedVersion: String?  // Version of installed helper
@Published var isInstalling: Bool         // Installation in progress
var needsUpdate: Bool                     // Update needed check
```

**Public Methods**:
```swift
/// Check installation status at /Library/PrivilegedHelperTools/
func checkInstallationStatus()

/// Install or update helper with user authorization
func install() async throws

/// Uninstall helper and launchd configuration
func uninstall() async throws

/// Install if needed, returns true if installation occurred
func installIfNeeded() async throws -> Bool
```

**Helper Installation Flow**:
1. User initiates operation requiring privileges
2. SecureOperationExecutor.execute() checks installer status
3. If not installed: calls HelperInstaller.install()
4. Creates AuthorizationRef via Security framework
5. Requests SMJobBless right with user interaction
6. Calls SMJobBless() to install helper
7. Validates installation, updates @Published properties
8. Returns to SecureOperationExecutor for XPC connection

**Error Handling**:
```swift
enum HelperInstallerError: LocalizedError {
    case alreadyInstalling                  // Install already in progress
    case authorizationFailed                // Could not create AuthorizationRef
    case authorizationDenied                // User denied or no admin rights
    case userCanceled                       // User canceled authorization prompt
    case blessFailed(String?)              // SMJobBless failed
    case uninstallFailed(String)            // Helper removal failed
}
```

**Configuration Files**:

1. **Launchd Plist** (`/Library/LaunchDaemons/com.hxd.ksapdismiss.helper.plist`):
```xml
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.hxd.ksapdismiss.helper</string>
    <key>MachServices</key>
    <dict>
        <key>com.hxd.ksapdismiss.helper</key>
        <true/>
    </dict>
</dict>
</plist>
```
- **Purpose**: Registers helper as a launchd service
- **Created by**: SMJobBless during installation
- **Removed by**: Helper uninstall or system update

2. **Helper Entitlements** (`Helper/Helper.entitlements`):
```xml
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <false/>
</dict>
</plist>
```
- **Purpose**: Disables sandboxing for privileged helper
- **Required**: Helper needs file system access for plist modification
- **Validation**: Code signing verifies entitlements

3. **Main App Info.plist**:
```
SMPrivilegedExecutables: {
    "com.hxd.ksapdismiss.helper": "<helper-code-signing-requirement>"
}
```
- **Purpose**: Registers helper bundle ID
- **Required by**: SMJobBless to validate installation
- **Update**: When helper bundle ID or requirements change

### Integration with SecureOperationExecutor

**Execution Sequence** (when operation requires privileges):
1. `SecureOperationExecutor.execute(reason:operation:)` called
2. Touch ID/Face ID authentication performed
3. Check: `installer.isInstalled`
   - If false: `try await installer.install()`
   - Shows authentication prompt for admin credentials
4. Check: `xpc.isConnected`
   - If false: `try await xpc.connectWithRetry()`
5. Execute privileged operation via XPC
6. Return result to caller

**Example Usage**:
```swift
try await SecureOperationExecutor.shared.execute(
    reason: "Verify your identity to modify keyboard settings",
    operation: {
        try await XPCClient.shared.addKeyboardEntries(entries)
    }
)
```

During execution:
- User sees Touch ID prompt
- If authentication succeeds, checks helper installation
- If helper not installed, user sees admin authorization prompt
- SMJobBless handles installation and launchd registration
- XPC connection established to newly installed helper
- Operation executes with elevated privileges

## Future Enhancements

1. **Connection Pooling**: Multiple concurrent operations
2. **Timeout Handling**: Add operation timeouts
3. **Callback Cancellation**: Support CancellationToken
4. **Metrics Collection**: Track latency, failure rates
5. **Version Negotiation**: Support multiple protocol versions
6. **Helper Auto-Update**: Background update mechanism
7. **Installation UI**: Progress indicator during installation
8. **Uninstall Cleanup**: Safe removal of helper artifacts
