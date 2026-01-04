# Sparkle Signing Tools

Download from: https://github.com/sparkle-project/Sparkle/releases

## Required Tools

| Tool | Purpose |
|------|---------|
| `generate_keys` | One-time EdDSA key generation |
| `sign_update` | Sign DMG for release |
| `generate_appcast` | Generate appcast.xml from releases |
| `BinaryDelta` | Create delta updates |

## Usage

```bash
# Generate new EdDSA key (one-time)
./generate_keys

# Sign a DMG
./sign_update path/to/app.dmg

# Sign with specific key file
./sign_update path/to/app.dmg --ed-key-file /path/to/key
```

## Notes

- These binaries are gitignored - download fresh from Sparkle releases
- Private key stored in macOS Keychain (or `~/Library/Sparkle/`)
- Public key must be added to app's Info.plist as `SUPublicEDKey`
