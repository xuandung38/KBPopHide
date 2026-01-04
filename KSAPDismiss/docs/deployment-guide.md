# Deployment & Release Guide

## Overview

KSAP Dismiss uses a fully automated release process via GitHub Actions. Releases are:
- Built as universal binaries (arm64 + x86_64)
- Packaged into DMG installers
- Cryptographically signed with EdDSA
- Distributed through Sparkle auto-update framework
- Published to GitHub Releases
- Deployed to GitHub Pages for update feeds

## Release Process

### Phase 1: Preparation

Run the release preparation script to validate the environment:

```bash
cd bin/
./prepare-release.sh
```

This script verifies:
- EdDSA key pair validity
- GitHub Secrets configuration
- GitHub Pages setup
- Version consistency between Info.plist and CHANGELOG.md
- Build success
- All tests passing

### Phase 2: Update Changelog

Edit `CHANGELOG.md`:
1. Move unreleased changes to new version section (format: `[X.Y.Z] - YYYY-MM-DD`)
2. Keep unreleased section empty
3. Ensure all categories present (Added, Changed, Fixed, Removed)

Example:
```markdown
## [1.1.3] - 2026-01-10

### Added
- Feature X
- Feature Y

### Fixed
- Bug fix A

## [Unreleased]

### Added

### Changed

### Fixed

### Removed
```

### Phase 3: Update Version

Update `KSAPDismiss/Info.plist`:

```bash
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString 1.1.3" KSAPDismiss/Info.plist
```

Verify:
```bash
/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" KSAPDismiss/Info.plist
```

### Phase 4: Commit Changes

```bash
git add CHANGELOG.md KSAPDismiss/Info.plist
git commit -m "chore: bump version to v1.1.3"
```

### Phase 5: Create Release Tag

```bash
git tag -a v1.1.3 -m "Release v1.1.3"
```

Push to remote:
```bash
git push origin main
git push origin v1.1.3
```

### Phase 6: Monitor Build

Visit GitHub Actions:
```
https://github.com/xuandung38/ksap-dismiss/actions
```

The workflow will:
1. Build universal binary
2. Package DMG
3. Sign with EdDSA
4. Generate appcast.xml
5. Deploy to GitHub Pages
6. Create GitHub Release

## GitHub Actions Workflow Details

### Trigger

Tags matching `v*.*.*` pattern automatically trigger the release workflow.

### Build Stage

Universal binary compilation for both architectures:

```bash
swift build -c release --arch arm64 --arch x86_64
```

### DMG Creation

1. Create `KSAPDismiss.app` bundle structure
2. Copy executable and Info.plist
3. Update version in plist from git tag
4. Generate DMG using `create-dmg`
5. Verify DMG file exists

### EdDSA Signing

1. Download Sparkle 2.8.1 tools
2. Verify Sparkle checksum (SHA-256)
3. Sign DMG with private key (environment variable)
4. Generate `.edSignature` file

**Security Note**: Private key stored as GitHub repository secret, never logged.

### Appcast Generation

1. Download Sparkle tools
2. Generate `appcast.xml` with:
   - Release metadata
   - Download URL
   - EdDSA signature
   - System requirements
3. Update `docs/appcast.xml`

### GitHub Pages Deployment

Deploy appcast to `gh-pages` branch:
- Branch: `gh-pages`
- Root directory
- Accessible at: `https://xuandung38.github.io/ksap-dismiss/appcast.xml`

### GitHub Release Creation

Create release with:
- Tag name: `v1.1.3`
- Release notes from CHANGELOG.md
- Attached files:
  - `KSAPDismiss-1.1.3.dmg`
  - `KSAPDismiss-1.1.3.dmg.edSignature`

## GitHub Configuration

### Required Secrets

Add to repository: `Settings > Secrets and variables > Actions`

| Secret | Value | Source |
|--------|-------|--------|
| `SPARKLE_PRIVATE_KEY` | EdDSA private key (44 chars, base64) | `bin/generate_keys` output |

### GitHub Pages Setup

1. Go to: `Settings > Pages`
2. Source: **Deploy from a branch**
3. Branch: **gh-pages** / **(root)**
4. Click **Save**

After first release, appcast.xml accessible at:
```
https://xuandung38.github.io/ksap-dismiss/appcast.xml
```

### Required Permissions

Ensure GitHub Actions can:
- Read code: ✓ (default)
- Write releases: ✓ (default)
- Deploy GitHub Pages: ✓ (requires Pages enabled)

## Installation for Users

### Manual Installation

1. Download `KSAPDismiss-X.Y.Z.dmg` from [Releases](https://github.com/xuandung38/ksap-dismiss/releases)
2. Open DMG file
3. Drag **KSAP Dismiss** to **Applications** folder
4. Launch from Applications

### Auto-Updates

After initial installation, app checks for updates:
1. Click menu bar icon → **Check for Updates...**
2. Or enable automatic checks in Settings → Updates tab
3. Sparkle downloads and installs new versions automatically
4. App relaunches on next launch

**No manual intervention required** - all future updates are handled automatically.

## EdDSA Signing Details

### Key Generation

Generated during Phase 1 setup:

```bash
cd bin/
./generate_keys
```

Creates:
- Public key: Stored in `Info.plist` (SUPublicEDKey)
- Private key: Stored in macOS Keychain

### Signature Verification

Sparkle verifies signatures:
1. Download DMG + signature file
2. Extract public key from Info.plist
3. Verify signature against public key
4. Proceed only if valid

**No user action required** - verification is automatic.

### Security Properties

- **Algorithm**: EdDSA (Ed25519)
- **Key size**: 256-bit
- **Base64 encoding**: Standard (no padding)
- **Prevents**: Man-in-the-middle attacks, tampering

## Troubleshooting

### Workflow Fails at Build

Check build locally:
```bash
swift build -c release
```

Common issues:
- Missing Swift tools
- Unsupported macOS version
- Code compilation errors

### Workflow Fails at DMG Creation

Verify `create-dmg` installed:
```bash
brew install create-dmg
```

Check disk space available.

### Appcast Generation Fails

Verify Sparkle tools downloaded correctly:
1. Check Sparkle checksum matches
2. Verify tools are executable
3. Check private key is valid

### GitHub Pages Not Updated

Verify:
1. Pages enabled in repository settings
2. Branch set to `gh-pages`
3. Source set to `(root)`
4. Check repository has `gh-pages` branch

Test access:
```bash
curl -I https://xuandung38.github.io/ksap-dismiss/appcast.xml
```

Should return HTTP 200.

### App Won't Update

Check:
1. Info.plist has correct `SUFeedURL`
2. Info.plist has correct `SUPublicEDKey`
3. appcast.xml accessible at URL
4. App has internet permission

Force update check:
- Menu bar icon → **Check for Updates...**
- Check logs: `~/Library/Logs/KSAP Dismiss/`

## System Requirements

**Minimum**:
- macOS 13.0 (Ventura) or later
- 50 MB disk space
- Administrator access for keyboard configuration

**Recommended**:
- macOS 14+ (Sonoma)
- Touch ID or Face ID for biometric authentication

## Distribution Channels

1. **GitHub Releases**: Manual downloads
   - [github.com/xuandung38/ksap-dismiss/releases](https://github.com/xuandung38/ksap-dismiss/releases)

2. **Auto-Updates**: Sparkle framework
   - Automatic checks enabled in Settings
   - Feed: `appcast.xml` on GitHub Pages

3. **Future**: App Store (if applicable)

## Version Management

### Semantic Versioning

Format: `MAJOR.MINOR.PATCH`

- **MAJOR** (v2.0.0): Breaking changes, major features
- **MINOR** (v1.1.0): New features, backward compatible
- **PATCH** (v1.0.1): Bug fixes, no new features

### Release Cadence

- Feature releases: Every 2-4 weeks
- Bug fix releases: As needed
- Patch releases: Within 24 hours of discovery

## Release Checklist

Before creating a release:

- [ ] All tests passing locally (`swift test`)
- [ ] CHANGELOG.md updated with version and date
- [ ] Info.plist version matches CHANGELOG
- [ ] No untracked or uncommitted changes
- [ ] EdDSA keys validated (`prepare-release.sh`)
- [ ] GitHub Secrets configured
- [ ] GitHub Pages enabled

After release:

- [ ] GitHub Actions workflow completed successfully
- [ ] GitHub Release created with notes
- [ ] appcast.xml updated on GitHub Pages
- [ ] appcast.xml accessible (HTTP 200)
- [ ] Test update through app (Check for Updates)

## Rollback Procedure

If a release has critical issues:

1. **Delete Release Tag**:
   ```bash
   git tag -d v1.1.3
   git push --delete origin v1.1.3
   ```

2. **Edit appcast.xml** (in `docs/appcast.xml`):
   - Remove problematic release entry
   - Restore previous appcast.xml from backup

3. **Revert GitHub Release**:
   - Edit release on GitHub
   - Mark as `Prerelease` or delete

4. **Notify Users** (if already updating):
   - Post issue with fix steps
   - Re-release with hotfix version

## Resources

- [Sparkle Documentation](https://sparkle-project.org/)
- [Keep a Changelog](https://keepachangelog.com/)
- [Semantic Versioning](https://semver.org/)
- [GitHub Actions](https://docs.github.com/en/actions)
- [EdDSA Algorithm](https://en.wikipedia.org/wiki/EdDSA)
