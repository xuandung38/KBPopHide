# Authentication & Secure Operations Guide

## Overview

This guide explains how to use the authentication layer in KSAP Dismiss to protect privileged operations with Touch ID / Face ID biometric authentication, combined with optional fallback to device passcode.

## Architecture

The authentication system consists of three main components:

1. **TouchIDAuthenticator** - Handles biometric authentication via LocalAuthentication framework
2. **SecureOperationExecutor** - Orchestrates authentication + XPC operations
3. **Error Handling** - Comprehensive error types with fallback guidance

## Quick Start

### Executing a Privileged Operation with Authentication

```swift
import SwiftUI

struct KeyboardSettingsView: View {
    var body: some View {
        Button("Remove All Keyboards") {
            Task {
                do {
                    try await SecureOperationExecutor.shared.removeAllKeyboardEntries()
                    // Success - show confirmation
                } catch let error as TouchIDError {
                    // Handle authentication error
                    handleAuthError(error)
                } catch {
                    // Handle XPC or other errors
                    showError(error)
                }
            }
        }
    }

    private func handleAuthError(_ error: TouchIDError) {
        if let description = error.errorDescription {
            // Show user-friendly error message
            showAlert(title: "Authentication Failed", message: description)
        }
    }
}
```

## Component Details

### TouchIDAuthenticator

The `TouchIDAuthenticator` singleton manages all biometric authentication operations.

#### Checking Biometric Availability

```swift
let authenticator = TouchIDAuthenticator.shared

// Check if device supports biometrics
if authenticator.isBiometricAvailable {
    // Show biometric UI
    let bioType = authenticator.biometricName  // "Touch ID", "Face ID", etc.
    updateUI(with: bioType)
} else {
    // Fall back to password-only authentication
    showPasswordPrompt()
}
```

#### Biometric-Only Authentication

```swift
do {
    try await TouchIDAuthenticator.shared.authenticate(
        reason: "Verify your identity to modify keyboard settings"
    )
    // Authentication successful
    performSecureOperation()
} catch let error as TouchIDError {
    switch error {
    case .userCanceled:
        // User dismissed the prompt - silent failure, no alert needed
        break
    case .notEnrolled:
        // User hasn't set up biometrics
        showSetupGuide()
    case .lockout:
        // Too many failed attempts - biometric locked
        showErrorAlert(error.errorDescription ?? "")
    case .notAvailable:
        // Hardware not available
        fall BackToPassword()
    default:
        showErrorAlert(error.errorDescription ?? "Unknown error")
    }
}
```

#### Authentication with Password Fallback

Recommended approach for sensitive operations:

```swift
do {
    try await TouchIDAuthenticator.shared.authenticateWithFallback(
        reason: "Verify your identity to disable Keyboard Setup Assistant"
    )
    // Authentication successful (via biometric or passcode)
    proceedWithOperation()
} catch let error as TouchIDError {
    switch error {
    case .userCanceled:
        // Silent - user dismissed
        break
    case .userFallback:
        // User requested password but canceled - this is after selection
        break
    default:
        if error.shouldShowAlert {
            showErrorAlert(error.errorDescription ?? "Authentication failed")
        }
    }
}
```

### SecureOperationExecutor

The `SecureOperationExecutor` orchestrates the complete flow: authenticate → verify connection → execute operation.

#### Generic Operation Execution

For custom operations requiring authentication:

```swift
let result = try await SecureOperationExecutor.shared.execute(
    reason: "Configure keyboard settings",
    operation: {
        try await customKeyboardOperation()
    }
)
```

**Execution Flow**:
1. Prompts user for Touch ID/Face ID authentication
2. If authentication fails but fallback is recommended, attempts passcode fallback
3. Ensures XPC connection to helper tool is established
4. Executes the provided operation closure
5. Returns result to caller
6. Cleans up on error

#### Keyboard-Specific Operations

Convenience methods for common operations:

```swift
// Add keyboard entries with authentication
try await SecureOperationExecutor.shared.addKeyboardEntries([
    (identifier: "0x1234", type: 0),
    (identifier: "0x5678", type: 1)
])

// Remove all keyboard entries with authentication
try await SecureOperationExecutor.shared.removeAllKeyboardEntries()

// Get keyboard status (no authentication required)
let (hasEntries, keyboards) = try await SecureOperationExecutor.shared.getKeyboardStatus()
```

## Error Handling Patterns

### Error Type Hierarchy

```
LocalizedError (Swift)
├── TouchIDError (Authentication)
├── XPCError (Communication)
└── Other system errors
```

### TouchIDError Cases and Handling

#### `userCanceled`
- **Cause**: User dismissed the biometric prompt
- **Show Alert**: No (silent failure)
- **Retry**: Yes, user can retry
- **Fallback**: No

```swift
case .userCanceled:
    // Silent - user chose to cancel
    // No alert needed
    break
```

#### `userFallback`
- **Cause**: User requested password during biometric prompt
- **Show Alert**: No
- **Retry**: Handled by `authenticateWithFallback()`
- **Fallback**: Yes (automatically attempted)

```swift
case .userFallback:
    // Only occurs with biometric-only authentication
    // Suggests re-attempting with fallback support
    break
```

#### `notEnrolled`
- **Cause**: No biometric data enrolled on device
- **Show Alert**: Yes
- **Action**: Guide user to Settings
- **Fallback**: Yes, to device passcode

```swift
case .notEnrolled:
    showAlert(
        title: "Biometric Not Set Up",
        message: "No biometric data enrolled. Please set up Touch ID in System Settings.",
        action: "Open Settings"
    ) {
        NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Library/PreferencePanes/Security.prefPane"))
    }
```

#### `lockout`
- **Cause**: Too many failed biometric attempts
- **Show Alert**: Yes
- **Duration**: Usually 15 minutes on macOS
- **Fallback**: Yes, to device passcode

```swift
case .lockout:
    showAlert(
        title: "Biometric Locked",
        message: "Biometric locked due to too many failed attempts. Please use password to unlock.",
        action: "Use Password"
    ) {
        // Can retry with authenticateWithFallback()
        retryWithPassword()
    }
```

#### `notAvailable(String?)`
- **Cause**: Hardware not available
- **Show Alert**: Yes
- **Fallback**: No biometric, but device passcode available

```swift
case .notAvailable(let reason):
    showAlert(
        title: "Biometric Not Available",
        message: reason ?? "Biometric authentication not available on this device"
    )
```

#### `failed`
- **Cause**: General authentication failure
- **Show Alert**: Yes
- **Retry**: Yes
- **Fallback**: Consider recommending fallback

```swift
case .failed:
    showAlert(
        title: "Authentication Failed",
        message: "Authentication failed. Please try again."
    )
```

#### `unknown(String)`
- **Cause**: Unmapped LocalAuthentication error
- **Show Alert**: Yes
- **Details**: Includes error message from LocalAuthentication framework

```swift
case .unknown(let message):
    showAlert(
        title: "Authentication Error",
        message: message
    )
```

### Helper Properties for UI Decisions

#### `shouldFallbackToPassword`

Indicates if user should be offered password fallback:

```swift
if error.shouldFallbackToPassword {
    showButton("Try with Password") {
        retryWithFallback()
    }
}
```

Returns `true` for:
- `.userFallback` - User requested password
- `.lockout` - Biometric locked, must use password
- `.notEnrolled` - No biometrics, use password

#### `shouldShowAlert`

Indicates if error should be displayed to user:

```swift
if error.shouldShowAlert {
    showErrorAlert(error.errorDescription ?? "Error")
}
```

Returns `false` for:
- `.userCanceled` - User choice, not an error
- `.userFallback` - Handled by fallback attempt

## Implementation Patterns

### Pattern 1: Simple Authentication + Operation

For straightforward authenticated operations:

```swift
@MainActor
class KeyboardManager: ObservableObject {
    @Published var isConfiguring = false

    func disableKeyboardAssistant() {
        Task {
            isConfiguring = true
            defer { isConfiguring = false }

            do {
                try await SecureOperationExecutor.shared
                    .removeAllKeyboardEntries()
                @MainActor in
                self.showSuccessMessage("Keyboard Setup Assistant disabled")
            } catch {
                handleError(error)
            }
        }
    }

    private func handleError(_ error: Error) {
        if let touchIDError = error as? TouchIDError {
            if touchIDError.shouldShowAlert {
                showAlert(touchIDError.errorDescription ?? "")
            }
        } else {
            showAlert("Operation failed: \(error.localizedDescription)")
        }
    }
}
```

### Pattern 2: Custom Operation with Context

For operations needing additional data:

```swift
func updateKeyboards(_ keyboards: [Keyboard]) {
    Task {
        do {
            let entries = keyboards.map { ($0.identifier, $0.type) }
            try await SecureOperationExecutor.shared.execute(
                reason: "Update \(keyboards.count) keyboard(s)",
                operation: {
                    try await XPCClient.shared.addKeyboardEntries(entries)
                }
            )
            showSuccessMessage("\(keyboards.count) keyboard(s) updated")
        } catch {
            handleError(error)
        }
    }
}
```

### Pattern 3: Graceful Degradation

For optional biometric authentication:

```swift
func performOptionallyAuthenticatedOperation() {
    Task {
        if TouchIDAuthenticator.shared.isBiometricAvailable {
            // Try authenticated path
            do {
                try await SecureOperationExecutor.shared.execute(
                    reason: "Verify your identity",
                    operation: { /* ... */ }
                )
            } catch {
                // Fall back to manual confirmation
                if confirmWithUser("Perform operation without authentication?") {
                    try await performOperation()
                }
            }
        } else {
            // Non-biometric device - ask for confirmation
            if confirmWithUser("Perform sensitive operation?") {
                try await performOperation()
            }
        }
    }
}
```

## Configuration

### Required Entitlements

Add to `KSAPDismiss.entitlements`:

```xml
<key>com.apple.security.device.local-authentication</key>
<true/>
```

### Info.plist Configuration

Add usage description (required for Face ID):

```xml
<key>NSFaceIDUsageDescription</key>
<string>KSAP Dismiss uses Face ID to authorize keyboard configuration changes.</string>
```

### Logging

Authenticator logs to subsystem "com.hxd.ksapdismiss", category "TouchID":

```swift
import os.log

// Access logs with Console.app
// Filter by process, then subsystem or category
```

## Testing

### Unit Tests

Comprehensive unit tests verify:
- Error descriptions and mappings
- Fallback logic
- Alert display decisions
- Singleton pattern

```swift
func testShouldFallbackToPassword() {
    XCTAssertTrue(TouchIDError.lockout.shouldFallbackToPassword)
    XCTAssertFalse(TouchIDError.userCanceled.shouldFallbackToPassword)
}

func testErrorDescriptions() {
    let error = TouchIDError.notEnrolled
    XCTAssertEqual(
        error.errorDescription,
        "No biometric data enrolled. Please set up Touch ID in System Settings."
    )
}
```

### Manual Testing

1. **Biometric Available**: Test on Mac with Touch ID (MacBook Pro, Air)
   - Verify prompt appears with correct reason
   - Test acceptance and rejection flows
   - Verify icon shows correct biometric type

2. **Biometric Unavailable**: Test on Mac without Touch ID
   - Verify graceful degradation to passcode
   - Test passcode-only authentication

3. **Enrollment Issues**: Test error conditions
   - Remove biometric enrollment: triggers `.notEnrolled`
   - Trigger lockout: multiple failed attempts
   - Verify error messages are actionable

4. **Integration**: Test with XPC operations
   - Verify auth success → operation executes
   - Verify auth failure → operation not executed
   - Check XPC connection established after auth

## Troubleshooting

### Biometric Prompt Not Appearing

**Possible Causes**:
1. Running in test environment (checks `isRunningTests`)
2. Device doesn't support biometrics
3. Biometric not enrolled
4. Missing entitlement

**Debug Steps**:
1. Check `TouchIDAuthenticator.isBiometricAvailable`
2. Verify entitlement in `.entitlements` file
3. Check Console.app logs: "com.hxd.ksapdismiss.TouchID"

### Operation Executes Without Authentication Prompt

**Possible Causes**:
1. Code not awaiting `SecureOperationExecutor.shared.execute()`
2. Test environment skips app initialization
3. XPC connection already established

**Verify**:
1. Ensure `async/await` syntax used correctly
2. Check `isRunningTests` guard in app initialization
3. Verify authentication called before operation

### Lockout State Not Recovering

**Expected Behavior**: Lockout expires after ~15 minutes on macOS

**Workaround**:
1. Wait for lockout to expire
2. Test with `authenticateWithFallback()` to use passcode
3. Re-enroll biometric data

## Best Practices

1. **Always provide fallback**: Use `authenticateWithFallback()` for sensitive operations
2. **Meaningful reasons**: Provide clear, user-friendly reason text
3. **Error handling**: Check `shouldShowAlert` before displaying errors
4. **Graceful degradation**: Handle biometric-unavailable devices
5. **Security**: Authenticate before every privileged operation
6. **User privacy**: Minimize frequency of authentication prompts
7. **Consistent UI**: Use application-wide error handling pattern
8. **Testing**: Mock TouchIDAuthenticator for UI tests

## Integration with KeyboardManager

The authentication layer integrates seamlessly with existing keyboard management:

```swift
class KeyboardManager: ObservableObject {
    // Use SecureOperationExecutor for all privileged operations

    @Published var isKSADisabled: Bool = false

    func toggleKSA() {
        Task { @MainActor in
            do {
                if isKSADisabled {
                    try await SecureOperationExecutor.shared
                        .removeAllKeyboardEntries()
                    self.isKSADisabled = false
                } else {
                    // Get current keyboards and update with auth
                    let keyboards = await getCurrentKeyboards()
                    try await SecureOperationExecutor.shared
                        .addKeyboardEntries(keyboards)
                    self.isKSADisabled = true
                }
            } catch {
                // Handle error
            }
        }
    }
}
```

## See Also

- **System Architecture**: `./system-architecture.md` - Complete architecture overview
- **Code Standards**: `./code-standards.md` - Development patterns and conventions
- **XPC Communication**: `./xpc-communication.md` - Helper tool integration
- **Project Overview**: `./project-overview-pdr.md` - Phase roadmap and requirements
