# Sparkle Auto-Update Integration

## Overview

KSAP Dismiss uses Sparkle 2.8.1 for automatic app updates. Sparkle handles:
- Checking for new versions
- Downloading DMG packages
- Verifying EdDSA signatures
- Installing updates
- Relaunching the app

This document covers setup, configuration, and troubleshooting.

## What is Sparkle?

Sparkle is the de-facto standard macOS auto-update framework:
- **Security**: Cryptographic signature verification
- **Reliability**: Atomic updates, rollback capability
- **User Experience**: Minimal interruption
- **Zero Installation**: No system requirements beyond macOS

## Installation & Configuration

### Phase 1: Framework Setup

Sparkle 2.8.1 is included in the project via Swift Package Manager (SPM).

**Package.swift dependencies**:
```swift
.package(url: "https://github.com/sparkle-project/Sparkle.git", from: "2.8.1")
```

**Target dependencies**:
```swift
.product(name: "Sparkle", package: "Sparkle")
```

### Phase 2: EdDSA Key Pair

Generate Ed25519 keypair for signing releases:

```bash
cd bin/
./generate_keys
```

**Output**:
- Public key: Displayed on screen (44 chars, base64)
- Private key: Stored in macOS Keychain

**Location in Keychain**:
- Service: `https://sparkle-project.org`
- Account: `ed25519`
- Password: Base64-encoded private key

### Phase 3: Configure Info.plist

Two key configuration values in `KSAPDismiss/Info.plist`:

#### 1. SUFeedURL

Appcast XML feed location:

```xml
<key>SUFeedURL</key>
<string>https://xuandung38.github.io/ksap-dismiss/appcast.xml</string>
```

**URL format**:
- Must be HTTPS
- Must be publicly accessible
- Should be stable (not GitHub releases page)
- GitHub Pages is ideal (free, stable, no auth)

**Update frequency**: Checked hourly (configurable in code)

#### 2. SUPublicEDKey

EdDSA public key for signature verification:

```xml
<key>SUPublicEDKey</key>
<string>ErqLZ+Wmkl9y9aUo2TjT8mlLm5KSr/gZPfX5HfU29Jk=</string>
```

**Format**: Base64-encoded Ed25519 public key

**Purpose**: Sparkle uses this to verify DMG signatures

**Security**: This key is public (safe to publish), corresponding private key must be kept secret.

### Phase 4: Entitlements

Required in `KSAPDismiss.entitlements`:

```xml
<key>com.apple.security.network.client</key>
<true/>
```

Allows app to make HTTP/HTTPS requests for update checking.

## Update Checking

### User-Initiated Check

User manually triggers from menu:

```swift
// In MenuBarManager or UpdaterViewModel
SUUpdater.shared().checkForUpdates(self)
```

Shows dialog immediately:
- "You're up to date!"
- "Version X.Y.Z is available"
- "Install and Relaunch" button

### Automatic Background Check

Configured in Settings → Updates tab:

```swift
// UpdaterViewModel.swift
SUUpdater.shared().automaticallyChecksForUpdates = true
SUUpdater.shared().updateCheckInterval = 3600  // 1 hour
```

**Behavior**:
- Checks silently in background
- Runs on schedule (default: hourly)
- Only alerts if update available
- Downloads in background
- Installs on next restart

**Configuration**:
- Can be toggled in UI
- Preference persisted in UserDefaults
- User can set custom interval

## Appcast XML Format

The `docs/appcast.xml` file describes available updates:

```xml
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0"
  xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle"
  xmlns:dc="http://purl.org/dc/elements/1.1/">

  <channel>
    <title>KSAP Dismiss</title>
    <link>https://github.com/xuandung38/ksap-dismiss</link>
    <description>Auto-update feed for KSAP Dismiss</description>
    <language>en</language>

    <!-- Most recent release first -->
    <item>
      <title>Version 1.1.3 - Sparkle Integration</title>
      <description>
        <![CDATA[
          New features:
          • Auto-update support
          • Improved error handling
        ]]>
      </description>
      <pubDate>Sun, 05 Jan 2026 12:00:00 +0000</pubDate>
      <sparkle:version>1.1.3</sparkle:version>
      <sparkle:shortVersionString>1.1.3</sparkle:shortVersionString>
      <enclosure
        url="https://github.com/xuandung38/ksap-dismiss/releases/download/v1.1.3/KSAPDismiss-1.1.3.dmg"
        sparkle:edSignature="EdDSA signature here"
        length="52428800"
        type="application/octet-stream"
      />
      <sparkle:minimumSystemVersion>13.0</sparkle:minimumSystemVersion>
    </item>

    <!-- Previous releases -->
    <item>
      <title>Version 1.1.2</title>
      <pubDate>Sun, 04 Jan 2026 00:00:00 +0000</pubDate>
      <sparkle:version>1.1.2</sparkle:version>
      <sparkle:shortVersionString>1.1.2</sparkle:shortVersionString>
      <enclosure
        url="https://github.com/xuandung38/ksap-dismiss/releases/download/v1.1.2/KSAPDismiss-1.1.2.dmg"
        sparkle:edSignature="EdDSA signature"
        length="52428800"
        type="application/octet-stream"
      />
      <sparkle:minimumSystemVersion>13.0</sparkle:minimumSystemVersion>
    </item>

  </channel>
</rss>
```

**XML Elements**:

| Element | Description |
|---------|-------------|
| `<title>` | Release name (displayed in dialog) |
| `<description>` | Release notes (shown to user) |
| `<pubDate>` | Release date (RFC 2822 format) |
| `sparkle:version` | Build number (internal, must increment) |
| `sparkle:shortVersionString` | User version (1.1.3 format) |
| `sparkle:edSignature` | EdDSA signature for DMG file |
| `enclosure[@url]` | DMG file download URL |
| `enclosure[@length]` | DMG file size in bytes |
| `sparkle:minimumSystemVersion` | Minimum macOS required |

**Generation**: Automatically generated by GitHub Actions workflow.

## EdDSA Signature Details

### Signature Creation

When releasing, GitHub Actions:

1. Builds DMG package
2. Downloads Sparkle signing tool
3. Signs DMG with private key:
   ```bash
   ./sign_update KSAPDismiss-1.1.3.dmg --ed-key-file key.txt
   ```
4. Creates `.edSignature` file
5. Extracts signature value into appcast.xml

### Signature Verification

When Sparkle downloads update:

1. Downloads DMG file
2. Downloads `.edSignature` file
3. Reads public key from Info.plist (`SUPublicEDKey`)
4. Verifies signature:
   ```
   verify(publicKey, signature, dmgHash) → true/false
   ```
5. **True**: Proceed with installation
6. **False**: Show error, block installation

### Security Properties

- **Algorithm**: EdDSA (NIST-approved)
- **Curve**: Curve25519
- **Key size**: 256-bit
- **Hash**: SHA-512 (implicit in EdDSA)
- **Attack resistance**:
  - Man-in-the-middle: HTTPS + signature
  - Tampering: Signature verification
  - Replay: Sparkle tracks installed version
  - Key compromise: Rotate keys + re-sign

## Update Flow (Technical)

```
1. App starts
   └─→ Check if auto-update enabled
       └─→ Spawn background update checker

2. Update checker runs (every hour)
   ├─→ Fetch appcast.xml from SUFeedURL
   ├─→ Parse version entries
   ├─→ Compare versions
   │   └─→ If CFBundleShortVersionString < latest:
   │       └─→ Update available!
   │
   └─→ Download DMG + signature
       ├─→ Store in temporary directory
       ├─→ Verify EdDSA signature
       │   ├─→ Signature valid: Continue
       │   └─→ Signature invalid: Abort, retry later
       │
       └─→ Mount DMG
           ├─→ Copy app from DMG to Applications/
           ├─→ Update code signature
           ├─→ Set permissions
           └─→ Unmount DMG

3. User launches app (or triggered by notification)
   ├─→ Detects newer version staged
   ├─→ Shows "Install and Relaunch" button
   └─→ On click: Kill app, install, relaunch
```

## Implementation in Code

### UpdaterViewModel.swift

Manages Sparkle updates in Settings:

```swift
@MainActor
final class UpdaterViewModel: NSObject, ObservableObject {
    @Published var automaticallyChecksForUpdates: Bool = true
    @Published var updateCheckInterval: TimeInterval = 3600
    @Published var isCheckingForUpdates = false
    @Published var lastCheckDate: Date?
    @Published var availableVersion: String?

    @ObservableReferenceable
    private let updater = SUUpdater.shared()

    // Enable automatic checking
    func enableAutoUpdates() {
        updater.automaticallyChecksForUpdates = true
        updater.updateCheckInterval = updateCheckInterval
    }

    // Manual update check
    func checkForUpdates() {
        isCheckingForUpdates = true
        updater.checkForUpdates(self)
        lastCheckDate = Date()
    }
}
```

### Settings UI Integration

Settings → Updates tab displays:
- "Check for updates automatically" toggle
- Update check interval selector
- "Check Now" button
- Last check date
- Available version (if any)

### Menu Item Integration

Menu bar shows:
```swift
MenuItem("Check for Updates...") {
    updaterViewModel.checkForUpdates()
}
```

## Error Handling

### Common Issues

#### 1. Appcast XML Not Accessible

**Symptom**: "Check for Updates" button grayed out or errors

**Cause**:
- GitHub Pages not enabled
- Wrong SUFeedURL in Info.plist
- Network unreachable
- 404 error from appcast

**Fix**:
1. Verify SUFeedURL is correct
2. Test in browser: Paste URL in Safari
3. Check GitHub Pages enabled in settings
4. Verify appcast.xml in gh-pages branch

#### 2. Signature Verification Failed

**Symptom**: Update downloaded but not installed, error dialog

**Cause**:
- SUPublicEDKey in Info.plist doesn't match private key
- DMG file corrupted in transit
- edSignature file missing or invalid

**Fix**:
1. Verify public key in Info.plist matches key from `generate_keys`
2. Check appcast.xml has correct edSignature
3. Check DMG file checksums
4. Re-sign DMG if needed: `./sign_update dmg-file`

#### 3. DMG Mount Fails

**Symptom**: "Could not install update" error

**Cause**:
- DMG file corrupted
- Disk space insufficient
- Permissions issue
- macOS version too old

**Fix**:
1. Verify macOS 13.0+
2. Check disk space: `df -h /`
3. Manual install: Download DMG, drag to Applications
4. Check system logs: `log stream | grep Sparkle`

#### 4. Version Comparison Issues

**Symptom**: Sparkle doesn't recognize newer version available

**Cause**:
- `sparkle:version` not incremented
- Version format incorrect (must be numeric)
- `sparkle:shortVersionString` format wrong

**Fix**:
1. Ensure `sparkle:version` increments (must be integer)
2. Use format `X.Y.Z` for shortVersionString
3. Verify greater-than comparison works

## Testing Locally

### Test Appcast Parsing

1. Start app with auto-update disabled
2. Edit Info.plist SUFeedURL to local URL:
   ```xml
   <string>file:///path/to/local/appcast.xml</string>
   ```
3. Create test appcast.xml locally
4. Trigger manual check: Menu → Check for Updates
5. Sparkle should parse local XML

### Test with Staging Appcast

Before releasing:

1. Generate test appcast.xml
2. Upload to GitHub Pages test branch
3. Update Info.plist to test URL
4. Run app, trigger update check
5. Verify signature passes with public key

### Disable Update for Testing

During development, disable Sparkle:

```swift
#if DEBUG
let updater = SUUpdater.shared()
updater.automaticallyChecksForUpdates = false
#endif
```

## Troubleshooting Commands

### Check Appcast Validity

```bash
# Test appcast URL
curl -I https://xuandung38.github.io/ksap-dismiss/appcast.xml

# Verify XML structure
curl https://xuandung38.github.io/ksap-dismiss/appcast.xml | xmllint --format -

# Check DMG available
curl -I https://github.com/xuandung38/ksap-dismiss/releases/download/v1.1.3/KSAPDismiss-1.1.3.dmg
```

### Verify Signature

```bash
# Check signature file exists
ls -lh KSAPDismiss-1.1.3.dmg.edSignature

# Validate key format
echo "ErqLZ+Wmkl9y9aUo2TjT8mlLm5KSr/gZPfX5HfU29Jk=" | base64 -D | od -An -tx1 | wc -w
# Should output "32" (256 bits = 32 bytes)
```

### View Info.plist Settings

```bash
# Check Sparkle configuration
/usr/libexec/PlistBuddy -c "Print :SUFeedURL" KSAPDismiss/Info.plist
/usr/libexec/PlistBuddy -c "Print :SUPublicEDKey" KSAPDismiss/Info.plist

# Check other update settings
/usr/libexec/PlistBuddy -c "Print :" KSAPDismiss/Info.plist | grep -i su
```

### Sparkle Logs

```bash
# View Sparkle framework logs
log stream --predicate 'process == "Sparkle"' --level debug

# Or in system.log
grep -i sparkle /var/log/system.log | tail -20
```

## Performance Considerations

### Update Check Impact

- **CPU**: Negligible (XML parsing)
- **Network**: ~10-50 KB (appcast.xml)
- **Memory**: ~1-2 MB peak
- **Duration**: <1 second typically

### Download Impact

- **Speed**: Depends on GitHub CDN (usually <5 seconds for 50MB)
- **Network**: ~50 MB per update
- **Disk**: ~100 MB temporary + ~50 MB final
- **Background**: Doesn't block app

### Installation Impact

- **Duration**: ~30 seconds
- **Disk I/O**: Intensive during copy/unmount
- **App restart**: Required
- **User**: Minimal interruption if backgrounded

## Versioning Strategy

### Version Numbering

Use semantic versioning: `MAJOR.MINOR.PATCH`

- **1.0.0** → **1.1.0**: New feature (minor increment)
- **1.1.0** → **1.1.1**: Bug fix (patch increment)
- **1.1.1** → **2.0.0**: Breaking change (major increment)

### Sparkle Version Numbers

Maintain two version values:

| Field | Example | Purpose |
|-------|---------|---------|
| `sparkle:version` | `111` | Internal build number (must increment) |
| `sparkle:shortVersionString` | `1.1.1` | User-facing version |

**Conversion**: v1.1.1 → version 111 (major × 100 + minor × 10 + patch)

## Phase 4: Advanced Features

### Delta Updates

Delta updates reduce bandwidth by 60-90% by distributing only binary patches instead of full releases.

**Implementation**:
- Sparkle 2.8.1+ automatically generates `.delta` patches
- GitHub Actions workflow creates delta files during release
- Appcast.xml lists both full and delta download options
- User's Sparkle automatically selects most efficient format

**Appcast XML Format** (delta support):
```xml
<item>
  <title>Version 1.2.0</title>
  <enclosure
    url="https://github.com/.../releases/download/v1.2.0/KSAPDismiss-1.2.0.dmg"
    sparkle:edSignature="signature-for-full"
    length="50000000"
    type="application/octet-stream"
  />
  <!-- Delta patch from 1.1.2 to 1.2.0 -->
  <enclosure
    url="https://github.com/.../releases/download/v1.2.0/KSAPDismiss-1.1.2-1.2.0.delta"
    sparkle:edSignature="signature-for-delta"
    sparkle:deltaFrom="1.1.2"
    length="3000000"
    type="application/octet-stream"
  />
</item>
```

**Benefits**:
- Faster downloads: 3-5 MB delta vs 50 MB full DMG
- Reduced bandwidth costs: ~94% savings vs full download
- Transparent to users: Sparkle handles selection
- Fallback to full: If delta unavailable, uses full DMG

### Beta Channel Support

Users can opt-in to pre-release versions for early access.

**Implementation**:
- Settings → Updates tab: "Include Beta Versions" toggle
- Separate appcast feed: `appcast-beta.xml`
- Beta versions marked with pre-release flag
- Version numbering: 1.2.0-beta.1, 1.2.0-rc.1

**Appcast XML Format** (beta support):
```xml
<item>
  <title>Version 1.2.0 Beta 1</title>
  <sparkle:version>120</sparkle:version>
  <sparkle:shortVersionString>1.2.0-beta.1</sparkle:shortVersionString>
  <!-- Mark as pre-release to prefer stable when available -->
  <sparkle:preReleaseVersionString>1.2.0-beta.1</sparkle:preReleaseVersionString>
</item>
```

**Feed Selection**:
```swift
// UpdaterViewModel.swift
var feedURL: URL {
    if includeBetaVersions {
        return URL(string: "https://xuandung38.github.io/ksap-dismiss/appcast-beta.xml")!
    } else {
        return URL(string: "https://xuandung38.github.io/ksap-dismiss/appcast.xml")!
    }
}
```

### Auto-Rollback Mechanism

Automatic rollback if app crashes shortly after update.

**Implementation**:
- RollbackManager tracks version launch success
- If app crashes within 5 minutes of update, triggers rollback
- Manual rollback available in Settings
- User prompted to report issue

**Rollback Flow**:
1. Update installed → app restarts
2. App launches → RollbackManager starts timer (5 min)
3. User takes action (e.g., interacts with settings)
4. Success recorded → timer canceled
5. On crash within window:
   - Detect previous version in backup
   - Show rollback dialog on next launch
   - User confirms rollback
   - Restore previous version
   - Remove broken version

**Settings UI**:
```
Updates Tab
├─ Check for updates automatically [toggle]
├─ Include Beta Versions [toggle]
├─ Last update: v1.2.0 (5 days ago)
└─ Rollback to previous version [button - if available]
   └─ Previous version: v1.1.2
```

### Analytics Integration

Privacy-first local JSON logging (opt-in).

**Implementation**:
- AnalyticsManager logs events to `~/Library/Application Support/ksap-dismiss/analytics.json`
- No network transmission by default
- User can opt-in to sending analytics
- Fully transparent data format

**Tracked Events**:
- App launch/exit
- Update check initiated/completed
- Update installed/failed
- Settings changed
- Feature used (keyboard management, etc.)

**Data Privacy**:
- Local storage only (user machine)
- No IP address collection
- No tracking cookies
- No external services
- User can delete logs anytime
- Opt-in for cloud transmission (future)

**Settings UI**:
```
Analytics Tab
├─ Help improve KSAP Dismiss [toggle]
│  └─ "Send crash reports and usage data"
├─ Data includes:
│  ├─ App usage patterns
│  ├─ Feature usage statistics
│  ├─ Crash reports
│  └─ OS and device info
├─ View collected data [button]
│  └─ Opens analytics.json in default editor
└─ Clear all analytics [button]
```

**JSON Format** (`analytics.json`):
```json
{
  "appVersion": "1.2.0",
  "firstLaunch": "2026-01-05T10:30:00Z",
  "events": [
    {
      "timestamp": "2026-01-05T10:30:15Z",
      "event": "app_launched",
      "metadata": {
        "osVersion": "14.2",
        "macModel": "MacBookPro18,1"
      }
    },
    {
      "timestamp": "2026-01-05T10:35:22Z",
      "event": "update_check",
      "metadata": {
        "automatic": true,
        "availableVersion": "1.2.1"
      }
    }
  ]
}
```

## Best Practices

1. **Always sign releases**: Never skip EdDSA signing
2. **Test appcast**: Validate XML before release
3. **Announce updates**: GitHub release notes
4. **Monitor adoption**: Track update success rate
5. **Support old versions**: Keep min 2 prev versions in appcast
6. **Test updates**: Manual DMG install before release
7. **Keep keys safe**: Private key in Keychain, GitHub Secret
8. **Update docs**: Keep release process documented
9. **Test delta patches**: Verify patches reduce file size
10. **Manage beta releases**: Keep separate feed for beta versions
11. **Privacy first**: Never send analytics without consent
12. **Document rollback**: Ensure users know rollback is available

## Migration from Older Sparkle

If updating from Sparkle 1.x:

1. Update SPM package version
2. Update public key format (if changed)
3. Re-generate signatures with new tools
4. Test signature verification
5. Update Info.plist with new key
6. Announce to users (update required)

## Resources

- [Sparkle Project](https://sparkle-project.org/)
- [Sparkle Documentation](https://sparkle-project.org/documentation/)
- [EdDSA Specification](https://tools.ietf.org/html/rfc8032)
- [GitHub Pages Help](https://docs.github.com/en/pages)
