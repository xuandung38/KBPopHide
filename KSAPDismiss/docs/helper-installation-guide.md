# Helper Installation & Management Guide

## Overview

Phase 4 implements automated installation of the privileged helper tool using Apple's SMJobBless framework. This guide explains the helper installation architecture, configuration requirements, and integration with the main application.

## What is SMJobBless?

SMJobBless (ServiceManagement Job Blessing) is Apple's framework for installing and managing privileged helper tools on macOS. It provides:

1. **Secure Installation**: Helper is code-signed and verified by the system
2. **Automatic Launching**: launchd automatically starts helper on first connection
3. **User Authorization**: Shows admin password prompt (not requiring full app elevation)
4. **Version Management**: Allows version checking and updates

## Architecture

### Components

#### 1. HelperInstaller (Main App)
- **Location**: `KSAPDismiss/XPC/HelperInstaller.swift`
- **Type**: `@MainActor` singleton
- **Frameworks**: ServiceManagement, Security, Foundation
- **Purpose**: Manage helper installation lifecycle

#### 2. Helper Tool Executable
- **Location**: `Helper/` directory
- **Bundle ID**: `com.hxd.ksapdismiss.helper`
- **Installation Path**: `/Library/PrivilegedHelperTools/com.hxd.ksapdismiss.helper`
- **Entitlements**: Disables sandboxing for system access

#### 3. Launchd Configuration
- **Location**: `Helper/launchd.plist`
- **Final Path**: `/Library/LaunchDaemons/com.hxd.ksapdismiss.helper.plist`
- **Purpose**: Registers helper as system service for auto-launching

### Installation Flow

```
User Initiates Operation
           ↓
SecureOperationExecutor.execute()
           ↓
        Check Helper Installation
           ↓
    Not Installed? → Call HelperInstaller.install()
           ↓
    Create AuthorizationRef
           ↓
    Request SMJobBless Right
           ↓
    Show Admin Authorization Prompt
           ↓
    Call SMJobBless()
           ↓
    Verify Installation
           ↓
    Update Published Properties
           ↓
    Establish XPC Connection
           ↓
    Execute Privileged Operation
```

## Configuration Files

### 1. Helper Entitlements

**File**: `Helper/Helper.entitlements`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <false/>
</dict>
</plist>
```

**Purpose**:
- Disables App Sandbox for helper tool
- Allows file system access for plist modification
- Required for privileged operations

**Why**: Helper needs to modify `/Library/Preferences/com.apple.keyboardtype.plist` which requires unrestricted file access.

### 2. Launchd Plist

**File**: `Helper/launchd.plist`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
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

**Purpose**:
- Registers helper service with launchd
- Specifies Mach service name for XPC
- Allows auto-launching by system

**Key Elements**:
- `Label`: Must match helper bundle ID
- `MachServices`: Enables XPC connection acceptance

**Installation**: SMJobBless copies this file to `/Library/LaunchDaemons/` during installation.

### 3. Main App Info.plist

**Key**: `SMPrivilegedExecutables`

```
<key>SMPrivilegedExecutables</key>
<dict>
    <key>com.hxd.ksapdismiss.helper</key>
    <string><helper-code-signing-requirement></string>
</dict>
```

**Purpose**:
- Registers privileged helper with system
- Contains code signing requirement
- Verified by SMJobBless

**Value**:
- `<helper-code-signing-requirement>`: Specifies what signatures are acceptable
- Format: `identifier "com.hxd.ksapdismiss.helper"` for development
- Updated with proper code signing for distribution

**Requirement Check**: SMJobBless verifies that installed helper matches this requirement.

### 4. Project Configuration

**File**: `project.yml`

```yaml
Helper:
  type: tool
  sources:
    - Helper
  settings:
    ENTITLEMENTS_FILE: Helper/Helper.entitlements
    PRODUCT_BUNDLE_IDENTIFIER: com.hxd.ksapdismiss.helper

KSAPDismiss:
  settings:
    HELPER_BUNDLE_ID: com.hxd.ksapdismiss.helper
```

**Purpose**:
- Configures helper as executable target
- Links entitlements file
- Sets bundle identifier

## API Reference

### HelperInstaller Class

**Type**: `@MainActor ObservableObject`

#### Properties

```swift
@Published var isInstalled: Bool           // Helper binary exists
@Published var installedVersion: String?   // Installed version
@Published var isInstalling: Bool          // Installation in progress
var needsUpdate: Bool { get }              // Update needed?
```

#### Methods

**Check Installation Status**
```swift
func checkInstallationStatus()
```
- Checks if helper binary exists at `/Library/PrivilegedHelperTools/`
- Updates `isInstalled` and `installedVersion`
- Called automatically on init
- Useful to refresh status after external changes

**Install Helper**
```swift
func install() async throws
```
- Creates AuthorizationRef
- Requests SMJobBless right
- Shows admin authorization prompt
- Calls SMJobBless() to install
- Updates published properties
- Throws `HelperInstallerError` on failure

**Uninstall Helper**
```swift
func uninstall() async throws
```
- Removes helper binary
- Removes launchd plist
- Updates `isInstalled` to false
- Throws `HelperInstallerError` on failure

**Install If Needed**
```swift
func installIfNeeded() async throws -> Bool
```
- Checks if installation needed
- Returns `true` if installation was performed
- Returns `false` if already installed
- Recommended method for auto-installation

#### Error Handling

```swift
enum HelperInstallerError: LocalizedError {
    case alreadyInstalling              // Install already in progress
    case authorizationFailed            // Could not create AuthorizationRef
    case authorizationDenied            // User denied or no admin rights
    case userCanceled                   // User canceled authorization prompt
    case blessFailed(String?)           // SMJobBless failed
    case uninstallFailed(String)        // Helper removal failed
}
```

## Usage Examples

### Basic Installation

```swift
@MainActor
class MyViewController {
    let installer = HelperInstaller.shared

    func installHelper() {
        Task {
            do {
                try await installer.install()
                print("Helper installed successfully")
            } catch {
                print("Installation failed: \(error.localizedDescription)")
            }
        }
    }
}
```

### Installation with Progress UI

```swift
struct ContentView: View {
    @StateObject var installer = HelperInstaller.shared

    var body: some View {
        if installer.isInstalling {
            ProgressView("Installing helper...")
        } else if installer.isInstalled {
            Label("Helper installed", systemImage: "checkmark.circle.fill")
        } else {
            Button("Install Helper") {
                Task {
                    try? await installer.install()
                }
            }
        }
    }
}
```

### Automatic Installation in SecureOperationExecutor

```swift
try await SecureOperationExecutor.shared.execute(
    reason: "Verify identity to modify keyboard settings",
    operation: {
        // This automatically:
        // 1. Authenticates with Touch ID
        // 2. Installs helper if needed
        // 3. Connects XPC
        // 4. Executes operation with elevated privileges
        try await XPCClient.shared.addKeyboardEntries(entries)
    }
)
```

### Checking Installation Status

```swift
let installer = HelperInstaller.shared
installer.checkInstallationStatus()

if installer.isInstalled {
    print("Helper v\(installer.installedVersion ?? "unknown") installed")
} else {
    print("Helper not installed")
}

if installer.needsUpdate {
    print("Helper update available")
}
```

## Security Considerations

### Privilege Escalation Flow

1. **Main App**: Runs as unprivileged user
2. **User Authorization**: Prompts for admin password (not app elevation)
3. **Helper Installation**: System verifies code signing
4. **Helper Execution**: Runs with elevated privileges
5. **Communication**: XPC over secure Mach IPC channel

**Security Advantages**:
- Main app never runs with elevated privileges
- User sees explicit authorization prompt
- System verifies helper code signing
- Minimal privilege scope (only helper operations)

### Code Signing Requirements

**Helper Must Be Code Signed**:
- Sign with same developer certificate as main app
- Include code signing requirement in Info.plist
- SMJobBless verifies signature before installation

**Verification**:
```bash
codesign -v /Library/PrivilegedHelperTools/com.hxd.ksapdismiss.helper
```

### File System Permissions

**Helper Installation Directories**:
- `/Library/PrivilegedHelperTools/` - Helper binary (root owned)
- `/Library/LaunchDaemons/` - Launchd plist (root owned)
- `/Library/Preferences/` - Target plist (read/write by helper)

**Access Control**:
- Only admin users can trigger installation
- Helper runs as root (via launchd)
- Operations limited to specific files

## Testing

### Unit Tests

Located in `Tests/KSAPDismissTests/Unit/HelperInstallerTests.swift`

```swift
// Singleton pattern
@MainActor
func testHelperInstallerSingleton()

// Installation status
@MainActor
func testInitialStateNotInstalling()

// Error handling
func testHelperInstallerErrorDescriptions()
func testAuthorizationDeniedErrorDescription()
func testUserCanceledErrorDescription()

// Update detection
@MainActor
func testNeedsUpdateWhenNotInstalled()
```

### Manual Testing

**Prerequisites**:
- Developer account for code signing
- Admin access on test Mac
- Helper executable in build

**Test Cases**:
1. **First Installation**
   - Trigger privileged operation
   - Observe authorization prompt
   - Verify helper installed to `/Library/PrivilegedHelperTools/`
   - Verify launchd plist created

2. **Already Installed**
   - Run second operation
   - Helper should connect immediately
   - No authorization prompt shown

3. **Version Mismatch**
   - Modify kHelperVersion
   - Install should detect version mismatch
   - Update logic (future)

4. **Installation Failure**
   - Cancel authorization prompt
   - Verify error shown to user
   - Verify app remains functional

## Troubleshooting

### Helper Installation Fails

**Error**: "Authorization denied"
- User doesn't have admin rights
- Prompt: Request admin to authorize

**Error**: "SMJobBless failed"
- Helper code signing invalid
- Check: `codesign -v /path/to/helper`

**Error**: "User canceled"
- User clicked "Cancel" in prompt
- Action: Retry or skip installation

### Helper Not Connecting

**Issue**: XPC connection fails after installation
- Verify helper installed: `ls /Library/PrivilegedHelperTools/com.hxd.ksapdismiss.helper`
- Check launchd logs: `log show --predicate 'process == "launchd"'`
- Verify plist: `cat /Library/LaunchDaemons/com.hxd.ksapdismiss.helper.plist`

### Version Mismatch

**Issue**: "Helper version mismatch" in logs
- Happens when `installedVersion != kHelperVersion`
- Old helper still installed from previous version
- Uninstall and reinstall helper

## Advanced Topics

### Helper Update Strategy

**Current**: Manual uninstall + reinstall
**Future**: Version negotiation in XPC
**Planned**: Background auto-update mechanism

### Auto-Launching Helper

**How It Works**:
1. Launchd loads plist on system boot
2. First XPC connection triggers launch
3. Helper runs until idle timeout
4. Launchd relaunches on next connection

**Benefits**:
- Helper not always running (saves resources)
- Automatically available when needed
- Handles helper crashes (relaunches)

### Removing Helper (Admin Only)

```bash
# Remove helper binary
sudo rm /Library/PrivilegedHelperTools/com.hxd.ksapdismiss.helper

# Remove launchd plist
sudo rm /Library/LaunchDaemons/com.hxd.ksapdismiss.helper.plist

# Unload launchd
sudo launchctl unload /Library/LaunchDaemons/com.hxd.ksapdismiss.helper.plist
```

Or use `HelperInstaller.uninstall()` method.

## References

- [SMJobBless Framework Documentation](https://developer.apple.com/documentation/servicemanagement/smjobbless)
- [Authorization Services Programming Guide](https://developer.apple.com/library/archive/documentation/Security/Conceptual/Authorization_Concepts/01introduction/introduction.html)
- [launchd Documentation](https://www.manpagez.com/man/8/launchd/)
- [Creating a Privileged Helper Tool](https://developer.apple.com/library/archive/samplecode/SMJobBless/Introduction/Intro.html)

## Document Metadata

- **Created**: 2026-01-04
- **Last Updated**: 2026-01-04
- **Status**: Active - Phase 4 Complete
- **Version**: 1.0
- **Coverage**: Helper installation, SMJobBless, configuration, testing, troubleshooting
