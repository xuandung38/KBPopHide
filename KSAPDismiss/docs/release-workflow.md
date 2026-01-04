# Release Workflow Documentation

## Overview

KSAP Dismiss release process is completely automated via GitHub Actions. This document explains the workflow, technical details, and troubleshooting.

## Release Workflow Diagram

```
Developer Actions          GitHub Actions (Automated)
────────────────          ────────────────────────────

1. Update CHANGELOG ──┐
2. Update Version    ├─→ Push to main
3. Commit changes    │
                     │
4. Create tag        ──→ Tag push triggers workflow
5. Push tag             │
                        ├─→ Checkout code
                        ├─→ Build release binary
                        ├─→ Create DMG package
                        ├─→ Download Sparkle tools
                        ├─→ Sign with EdDSA
                        ├─→ Generate appcast.xml
                        ├─→ Deploy to GitHub Pages
                        └─→ Create GitHub Release
                              │
                              └─→ Release complete!
                                  Users can download
                                  & auto-update
```

## Workflow Details

### 1. Trigger

**File**: `.github/workflows/release.yml`

```yaml
on:
  push:
    tags:
      - 'v*.*.*'  # Matches: v1.0.0, v1.1.2, v2.0.0, etc.
```

**When it runs**:
- Any push of a tag matching `v*.*.*` pattern
- Example: `git push origin v1.1.3`

**Who can trigger**:
- Any contributor with write access
- Typically: repository owner or release manager

### 2. Environment Variables

```yaml
env:
  APP_NAME: KSAPDismiss
  BUNDLE_ID: com.hxd.ksapdismiss
```

Used throughout workflow for consistency.

### 3. Job: build-and-release

**Runs on**: `macos-latest` (latest macOS in GitHub Actions)

**Steps**:

#### Step 1: Checkout Code
```yaml
uses: actions/checkout@v4
with:
  fetch-depth: 0  # Full history for changelog parsing
```

Clones repository with complete history.

#### Step 2: Setup Xcode
```yaml
uses: maxim-lobanov/setup-xcode@v1
with:
  xcode-version: latest-stable
```

Ensures latest stable Xcode tools available.

#### Step 3: Install Dependencies
```bash
brew install create-dmg
```

Installs `create-dmg` utility for DMG generation.

#### Step 4: Build Release Binary

```bash
swift build -c release --arch arm64 --arch x86_64
```

Produces universal binary:
- arm64: Apple Silicon (M1, M2, M3, etc.)
- x86_64: Intel Macs

**Output**: `.build/apple/Products/Release/KSAPDismiss`

**Optimization**: `-c release` enables compiler optimizations

#### Step 5: Create DMG

1. Create app bundle structure:
   ```
   temp_dmg/
   └── KSAPDismiss.app/
       ├── Contents/
       │   ├── MacOS/
       │   │   └── KSAPDismiss (executable)
       │   └── Info.plist
   ```

2. Update Info.plist version from git tag:
   ```bash
   /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString 1.1.3"
   /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $GITHUB_RUN_NUMBER"
   ```

3. Set executable permissions:
   ```bash
   chmod +x Contents/MacOS/KSAPDismiss
   ```

4. Create DMG using `create-dmg`:
   ```
   KSAPDismiss-1.1.3.dmg (600x400 window, 100px icons)
   ```

**Output**: `build/KSAPDismiss-1.1.3.dmg`

#### Step 6: Download Sparkle Tools

**Sparkle version**: 2.8.1

```bash
curl -L https://github.com/sparkle-project/Sparkle/releases/download/2.8.1/Sparkle-2.8.1.tar.xz
```

**Security**: SHA-256 checksum verification

```bash
echo "sha256hash  sparkle.tar.xz" | shasum -a 256 -c -
```

Prevents man-in-the-middle attacks.

**Tools extracted**:
- `sign_update`: Signs DMG with EdDSA
- `generate_appcast`: Generates Sparkle feed

#### Step 7: Sign DMG with EdDSA

Uses private key from GitHub Secrets:

```bash
./sign_update build/KSAPDismiss-1.1.3.dmg \
  --ed-key-file /tmp/sparkle_key.txt
```

**Outputs**:
- Original: `KSAPDismiss-1.1.3.dmg`
- Signature: `KSAPDismiss-1.1.3.dmg.edSignature`

**Security**:
- Key file: Restrictive permissions (`077`)
- Cleanup: Securely deleted after use
- Logging: Key contents never printed

**Signature contains**:
- DMG hash
- EdDSA signature
- Metadata for verification

#### Step 8: Generate Appcast

Creates Sparkle update feed:

```bash
./generate_appcast \
  --link https://github.com/xuandung38/ksap-dismiss/releases \
  --download-url-prefix https://github.com/xuandung38/ksap-dismiss/releases/download/v1.1.3/ \
  --ed-key-file /tmp/sparkle_key.txt \
  --output docs/appcast.xml \
  build/
```

**Output**: `docs/appcast.xml`

**XML structure**:
```xml
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="...">
  <channel>
    <title>KSAP Dismiss</title>
    <item>
      <title>Version 1.1.3</title>
      <pubDate>Sun, 05 Jan 2026 00:00:00 +0000</pubDate>
      <sparkle:version>1.1.3</sparkle:version>
      <sparkle:shortVersionString>1.1.3</sparkle:shortVersionString>
      <enclosure
        url="https://...releases/download/v1.1.3/KSAPDismiss-1.1.3.dmg"
        sparkle:edSignature="..."
        length="..."
        type="application/octet-stream"
      />
      <sparkle:minimumSystemVersion>13.0</sparkle:minimumSystemVersion>
    </item>
  </channel>
</rss>
```

#### Step 9: Deploy to GitHub Pages

Publishes appcast.xml via GitHub Pages:

```yaml
uses: peaceiris/actions-gh-pages@v3
with:
  github_token: ${{ secrets.GITHUB_TOKEN }}
  publish_dir: ./docs
  publish_branch: gh-pages
  commit_message: "Update appcast.xml for v1.1.3"
  enable_jekyll: false
```

**What happens**:
1. Creates/updates `gh-pages` branch
2. Commits `docs/` contents
3. GitHub Pages serves from branch root
4. `.nojekyll` file disables Jekyll processing

**Result**: Appcast accessible at:
```
https://xuandung38.github.io/ksap-dismiss/appcast.xml
```

#### Step 10: Create GitHub Release

Publishes release on GitHub:

```yaml
uses: softprops/action-gh-release@v1
```

**Attached files**:
- `KSAPDismiss-1.1.3.dmg` (installer)
- `KSAPDismiss-1.1.3.dmg.edSignature` (signature)

**Release body** (auto-generated from CHANGELOG):
```markdown
## KSAP Dismiss v1.1.3

### What's New

See [CHANGELOG.md](https://github.com/.../CHANGELOG.md#113) for details.

### Installation

1. Download `KSAPDismiss-1.1.3.dmg`
2. Open the DMG file
3. Drag KSAP Dismiss to your Applications folder
4. Launch from Applications

### Auto-Updates

This release includes Sparkle auto-update support...

### Requirements

- macOS 13.0 (Ventura) or later
- Administrator access for keyboard configuration
```

## Update Flow (User Perspective)

### Auto-Check Disabled

User manually checks for updates:

```
App Menu → Check for Updates...
  │
  ├─→ Fetch appcast.xml from GitHub Pages
  │     └─→ Parse version entries
  │         └─→ Compare with current version
  │
  └─→ If newer version available:
        ├─→ Show update dialog
        ├─→ User clicks "Update"
        ├─→ Download DMG + signature
        ├─→ Verify EdDSA signature
        ├─→ Mount DMG
        ├─→ Replace app in Applications/
        └─→ Relaunch with new version
```

### Auto-Check Enabled

Automatic background updates:

```
Every check interval (usually hourly):
  │
  ├─→ Fetch appcast.xml
  ├─→ Check for new version
  │
  └─→ If new version available:
        ├─→ Download silently
        ├─→ Verify signature
        ├─→ Stage for installation
        └─→ Install on next app restart
```

**No user interaction required** - Sparkle handles everything.

## Signature Verification Flow

```
1. Sparkle downloads DMG + edSignature file
                │
2. Read public key from Info.plist (SUPublicEDKey)
                │
3. Verify signature(edSignature) with public key
                │
         ┌──────┴──────┐
         │             │
      Valid         Invalid
         │             │
    Continue      Show error
    Update       Block update
```

**Invalid signature means**:
- File corrupted in transit
- Man-in-the-middle attack
- Signed with wrong key
- Update is blocked, user retries later

## GitHub Secrets Configuration

Required secret:

| Name | Value | Type |
|------|-------|------|
| `SPARKLE_PRIVATE_KEY` | EdDSA private key | String |

**Setup**:
1. Go to: `https://github.com/xuandung38/ksap-dismiss/settings/secrets/actions`
2. Click "New repository secret"
3. Name: `SPARKLE_PRIVATE_KEY`
4. Value: Copy from `bin/generate_keys` output
5. Click "Add secret"

**Security**:
- Never logged in workflow output
- Only available to Actions
- Can be rotated/revoked anytime
- Individual per repository

## Workflow File Location

**Path**: `.github/workflows/release.yml`

**Key sections**:
- Lines 1-11: Trigger configuration
- Lines 12-38: Build stage
- Lines 39-93: DMG creation
- Lines 94-116: Sparkle tools download
- Lines 117-140: EdDSA signing
- Lines 141-167: Appcast generation
- Lines 168-175: GitHub Pages deployment
- Lines 176-214: GitHub Release creation

## Monitoring & Troubleshooting

### Check Workflow Status

1. Go to: `https://github.com/xuandung38/ksap-dismiss/actions`
2. Find workflow by tag name (e.g., "v1.1.3")
3. Click to see detailed logs

### Common Issues & Solutions

#### Build Fails

**Log output**: "Release build failed"

**Solutions**:
1. Run locally: `swift build -c release`
2. Check Swift version: `swift --version`
3. Check Xcode: `xcode-select --install`

#### DMG Creation Fails

**Log output**: "DMG not created"

**Solutions**:
1. Check disk space: `df -h`
2. Verify `create-dmg` available
3. Check executable permissions

#### Sparkle Tools Download Fails

**Log output**: "Sparkle checksum verification failed"

**Solutions**:
1. Verify checksum matches Sparkle 2.8.1 release
2. Check internet connectivity
3. May be temporary GitHub API issue

#### EdDSA Signing Fails

**Log output**: "signature file not found"

**Solutions**:
1. Verify `SPARKLE_PRIVATE_KEY` secret exists
2. Check key format (base64, 44 chars)
3. Validate key with: `bin/validate_keys.sh`

#### Appcast Generation Fails

**Log output**: "appcast.xml not generated"

**Solutions**:
1. Check Sparkle tools extracted correctly
2. Verify key file permissions
3. Check output directory writable

#### GitHub Pages Deployment Fails

**Log output**: "failed to publish to gh-pages"

**Solutions**:
1. Enable GitHub Pages in settings
2. Check `gh-pages` branch exists
3. Verify GITHUB_TOKEN permissions

## Rollback Procedure

If release has critical bugs:

```bash
# 1. Delete git tag (local + remote)
git tag -d v1.1.3
git push --delete origin v1.1.3

# 2. Edit appcast.xml in docs/
# Remove the release entry manually

# 3. Commit appcast change
git add docs/appcast.xml
git commit -m "chore: rollback appcast for v1.1.3"
git push origin main

# 4. Create hotfix version (v1.1.4)
# Fix bug, update version, create new tag
```

Users with auto-update will:
- See no new version available
- Keep current version
- Get next release (v1.1.4) when ready

## Performance Notes

**Build time**: ~2-5 minutes
- Compilation dominates
- Caching minimal for release builds

**DMG creation**: ~30 seconds
- File copying
- DMG formatting
- Image finalization

**Sparkle operations**: ~1 minute
- Tools download (cached often)
- Signing
- Appcast generation

**GitHub Pages**: ~30 seconds
- Push to gh-pages branch
- GitHub Pages sync

**Total workflow**: ~5-10 minutes

## Security Considerations

### Secrets Management

- `SPARKLE_PRIVATE_KEY` stored encrypted
- Never exposed in logs
- Deleted from workflow environment
- Can be rotated independently

### Signature Verification

- EdDSA (NIST standard)
- 256-bit key size
- Offline key storage (Keychain)
- Online verification during update

### DMG Integrity

- Signed immediately after creation
- Signature included in appcast
- Verified before installation
- Prevents tampering

### GitHub Pages Security

- HTTPS enforced
- No JavaScript execution (`.nojekyll`)
- Served from read-only repository
- No authentication required

## Version Management

**Info.plist** contains two version fields:

| Field | Set By | Purpose |
|-------|--------|---------|
| `CFBundleShortVersionString` | Developer | User-facing version (1.1.3) |
| `CFBundleVersion` | Workflow | Build number (GitHub run #) |

Workflow automatically updates `CFBundleVersion` from `GITHUB_RUN_NUMBER` (unique per workflow run).

## Resources

- [Sparkle 2 Documentation](https://sparkle-project.org/)
- [GitHub Actions Syntax](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions)
- [EdDSA Documentation](https://tools.ietf.org/html/rfc8032)
- [DMG Format](https://en.wikipedia.org/wiki/Apple_Disk_Image)
