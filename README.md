# KSAP Dismiss

A modern macOS menu bar utility to disable/enable the Keyboard Setup Assistant popup.

## Overview

KSAP Dismiss is a native Swift application that allows you to suppress the "Keyboard Setup Assistant" dialog that appears when you connect keyboards to your Mac. Built with SwiftUI and using modern Swift concurrency, it provides a clean, intuitive interface for managing keyboard configuration prompts.

**Perfect for:**
- KVM switch users who frequently switch between computers
- Users with multiple USB/Bluetooth keyboards
- IT professionals managing multiple Macs
- Anyone tired of identifying keyboard types repeatedly

## Features

- **Menu Bar Integration**: Lightweight menu bar app with visual status indicator
- **Settings Window**: Comprehensive settings interface with multiple tabs:
  - General settings for quick enable/disable
  - Keyboard list view showing detected and configured keyboards
  - About information
- **Automatic Mode**: Real-time USB keyboard detection with silent auto-suppress - no more manual clicking!
- **Start at Login**: Auto-launch with macOS via SMAppService integration
- **Automatic Detection**: Detects connected USB keyboards automatically
- **Smart Fallbacks**: Falls back to common Apple keyboard identifiers if detection fails
- **Visual Feedback**: Real-time status updates with color-coded indicators
- **Authorization Caching**: Secure privilege elevation with session-based credential caching
- **Multi-language**: English and Vietnamese UI support with live language switching
- **Modern Swift**: Built with Swift Concurrency (async/await) and SwiftUI

## Requirements

- **macOS**: 13.0 (Ventura) or later
- **Privileges**: Administrator access (for modifying system preferences)
- **Xcode**: 15.0+ (for building from source)

## Installation

### Option 1: Build with Xcode (Recommended)

```bash
# Clone the repository
git clone https://github.com/xuandung38/ksap-dismiss.git
cd ksap-dismiss

# Open in Xcode
open KSAPDismiss.xcodeproj
# Or use xcodegen to generate project:
# xcodegen generate

# Build and run from Xcode (⌘R)
```

### Option 2: Build with Makefile

```bash
# Build the app
make build

# Create app bundle and run
make run

# Install to /Applications
make install

# Clean build artifacts
make clean
```

### Option 3: Build with Swift Package Manager

```bash
swift build -c release

# Create app bundle
make bundle
```

**Note**: For proper signing, distribution, and full app functionality, building with Xcode is recommended.

## Usage

### Quick Start

1. **Launch** KSAP Dismiss - a keyboard icon appears in your menu bar
2. **Click** the menu bar icon to see options
3. **Disable Popup** - Select this option to suppress the Keyboard Setup Assistant
4. **Enter Password** when prompted (admin credentials required)
5. **Re-enable** anytime by selecting "Enable Popup"

### Menu Bar Icons

- **(outline)**: Keyboard Setup Assistant is **enabled** (popups will appear)
- **(filled)**: Keyboard Setup Assistant is **disabled** (popups suppressed)

### Settings Window

Access the full settings window from the menu bar menu:

- **General Tab**: Quick enable/disable controls with status information
  - **Automatic Mode**: Toggle to auto-suppress new keyboards when connected
  - **Start at Login**: Toggle to launch KSAP Dismiss automatically with macOS
  - **Language**: Switch between English and Vietnamese
- **Keyboards Tab**: View detected keyboards and their configuration status
- **About Tab**: Application information and credits

### Automatic Mode

When enabled, KSAP Dismiss monitors USB ports in real-time using IOKit notifications. When a new keyboard is connected, it's automatically configured to suppress the Keyboard Setup Assistant - no password prompts, no manual intervention.

## How It Works

The Keyboard Setup Assistant (KSA) stores keyboard configurations in:
```
/Library/Preferences/com.apple.keyboardtype.plist
```

KSAP Dismiss manages this preference file by:

1. **Detecting** connected USB keyboards using IOKit
2. **Adding entries** to the plist with proper vendor/product IDs in format: `VendorID-ProductID-0`
3. **Setting keyboard types** (40=ANSI, 41=ISO, 42=JIS) so macOS recognizes them as configured
4. **Using privileged operations** via Authorization Services for secure system-level changes

When the plist contains keyboard entries, macOS assumes those keyboards have already been identified and skips the setup dialog.

## Technical Details

### Architecture

- **SwiftUI**: Modern declarative UI framework
- **Swift Concurrency**: Async/await for non-blocking operations
- **ObservableObject Pattern**: Reactive state management with `KeyboardManager`
- **Authorization Services**: Secure privilege elevation
- **IOKit**: Low-level USB keyboard detection
- **MenuBarExtra**: Native menu bar integration (macOS 13+)

### Key Components

- `KSAPDismissApp.swift`: Main app entry point with MenuBarExtra
- `KeyboardManager.swift`: Core business logic and state management
- `AuthorizationHelper.swift`: Secure privilege elevation handling
- `USBMonitor.swift`: Real-time IOKit USB keyboard monitoring
- `AppSettings.swift`: Settings management with SMAppService for Login Item
- `LanguageManager.swift`: Live language switching support
- `MenuBarView.swift`: Quick access menu interface
- `SettingsView.swift`: Comprehensive settings window
- `KeyboardListView.swift`: Keyboard detection and list display

### Keyboard Type Codes

- `40`: ANSI (US standard layout)
- `41`: ISO (European layout with extra key)
- `42`: JIS (Japanese layout)

### Default Fallbacks

If automatic detection fails, KSAPDismiss uses these common identifiers:
- `1452-635-0`: Apple USB Keyboard
- `1452-636-0`: Apple Wireless Keyboard
- `0-0-0`: Generic keyboard fallback

## Building from Source

### Prerequisites

```bash
# Install Xcode Command Line Tools
xcode-select --install

# Optional: Install xcodegen for project generation
brew install xcodegen
```

### Build Commands

```bash
# Using Makefile (all targets)
make help          # Show available commands
make build         # Build the application
make xcode         # Generate Xcode project
make bundle        # Create app bundle from SPM build
make run           # Build and run
make install       # Install to /Applications
make clean         # Remove build artifacts

# Using Xcode
xcodebuild -project KSAPDismiss.xcodeproj \
           -scheme KSAPDismiss \
           -configuration Release \
           build

# Using Swift Package Manager
swift build -c release
swift run KSAPDismiss
```

## Troubleshooting

### "Operation not permitted" error
- **Solution**: Ensure you're entering the correct administrator password when prompted
- The app requires admin privileges to modify system preferences

### Keyboard Setup Assistant still appears
- **Try**: Disconnect and reconnect your keyboard
- **Or**: Restart your Mac to ensure changes take effect
- **Check**: Open Settings window → Keyboards tab to verify your keyboard is listed

### Menu bar icon not appearing
- **Requirement**: macOS 13.0 (Ventura) or later
- The app uses `MenuBarExtra` which is only available on Ventura and newer
- **Check**: System Settings → Appearance → Show menu bar extras to ensure menu bar items aren't hidden

### Settings window doesn't open
- **Try**: Click the menu bar icon and select "Settings..." from the menu
- **Or**: Use the keyboard shortcut ⌘, (Command-Comma)

### App won't launch
- **Check**: Console.app for error messages
- **Verify**: You're running macOS 13.0 or later
- **Try**: Remove any cached app data: `~/Library/Preferences/com.youridentifier.KSAPDismiss.plist`

## Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues for bugs and feature requests.

### Development Setup

1. Fork the repository
2. Clone your fork
3. Create a feature branch: `git checkout -b feature/amazing-feature`
4. Make your changes
5. Test thoroughly
6. Commit: `git commit -m 'Add amazing feature'`
7. Push: `git push origin feature/amazing-feature`
8. Open a Pull Request

## Security Considerations

- **Privilege Elevation**: Uses macOS Authorization Services (not AppleScript) for secure admin operations
- **Credential Caching**: Administrator credentials are cached only for the session to minimize password prompts
- **System Integrity**: Only modifies the keyboard type preference file, no other system files
- **No Network Access**: Completely offline app, no data transmission

## Compatibility

| macOS Version | Status |
|--------------|--------|
| macOS 15 (Sequoia) | Supported |
| macOS 14 (Sonoma) | Supported |
| macOS 13 (Ventura) | Supported (minimum) |
| macOS 12 (Monterey) | Not supported (MenuBarExtra unavailable) |

## Roadmap

- [x] Launch at login option
- [x] Automatic mode (suppress on first keyboard connection)
- [x] Multi-language support (English/Vietnamese)
- [ ] Support for Bluetooth keyboard detection
- [ ] Custom keyboard type selection per device
- [ ] Import/export keyboard configurations
- [ ] Sparkle framework for automatic updates

## Credits

**Author**: Xuan Dung, Ho  
**Contact**: me@hxd.vn  
**Website**: [hxd.vn](https://hxd.vn)

Built with Swift and SwiftUI for the macOS community.

## Support

If you find this app useful, please consider:
- Starring the repository
- Reporting bugs
- Suggesting features
- Contributing code

For issues and support, please contact me@hxd.vn or visit the [GitHub Issues](https://github.com/xuandung38/ksap-dismiss/issues) page.

