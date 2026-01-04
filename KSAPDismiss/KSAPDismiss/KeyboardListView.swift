import SwiftUI

// MARK: - Keyboard Model

struct KeyboardInfo: Identifiable, Hashable {
    let id = UUID()
    let identifier: String
    let vendorID: Int
    let productID: Int
    let keyboardType: Int
    let keyboardTypeName: String

    var displayName: String {
        // Known vendor IDs
        switch vendorID {
        case 1452: return "Apple Keyboard"
        case 1133: return "Logitech Keyboard"
        case 1241: return "Razer Keyboard"
        case 1118: return "Microsoft Keyboard"
        case 4871: return "HHKB Keyboard"
        case 10730: return "Keychron Keyboard"
        default:
            if vendorID == 0 && productID == 0 {
                return "Generic Fallback"
            }
            return "USB Keyboard (\(vendorID))"
        }
    }
}

// MARK: - Keyboard List View

struct KeyboardListView: View {
    @EnvironmentObject var keyboardManager: KeyboardManager
    @State private var connectedKeyboards: [KeyboardInfo] = []
    @State private var isDetecting = false
    @State private var showingError = false
    @State private var errorMessage = ""

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L("Keyboards"))
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text(L("Configured and detected keyboards"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button {
                    Task {
                        await detectKeyboards()
                    }
                } label: {
                    HStack(spacing: 6) {
                        if isDetecting {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                        Text(L("Detect"))
                    }
                }
                .buttonStyle(.bordered)
                .disabled(isDetecting)
            }
            .padding(24)

            Divider()

            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Configured Keyboards Section
                    if let configuredKeys = keyboardManager.configuredKeyboards, !configuredKeys.isEmpty {
                        KeyboardSection(
                            title: L("Configured Keyboards"),
                            subtitle: L("Currently registered in macOS plist"),
                            icon: "checkmark.circle.fill",
                            iconColor: .green
                        ) {
                            ForEach(parseConfiguredKeyboards(configuredKeys), id: \.self) { keyboard in
                                KeyboardRow(keyboard: keyboard, isConfigured: true)
                            }
                        }
                    }

                    // Connected Keyboards Section
                    if !connectedKeyboards.isEmpty {
                        KeyboardSection(
                            title: L("Connected Keyboards"),
                            subtitle: L("Detected via USB"),
                            icon: "cable.connector",
                            iconColor: .blue
                        ) {
                            ForEach(connectedKeyboards) { keyboard in
                                KeyboardRow(
                                    keyboard: keyboard,
                                    isConfigured: isKeyboardConfigured(keyboard)
                                )
                            }
                        }
                    }

                    // Empty State
                    if keyboardManager.configuredKeyboards?.isEmpty ?? true && connectedKeyboards.isEmpty {
                        EmptyStateView()
                    }

                    // Info Card
                    InfoCard()
                }
                .padding(24)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            Task {
                await detectKeyboards()
            }
        }
        .alert(Text(L("Error")), isPresented: $showingError) {
            Button(L("OK"), role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }

    private func detectKeyboards() async {
        isDetecting = true
        defer { isDetecting = false }

        // Run detection on background thread
        let detected = await Task.detached(priority: .userInitiated) {
            USBKeyboardDetector.detectConnectedKeyboards()
        }.value

        connectedKeyboards = detected.map { keyboard in
            KeyboardInfo(
                identifier: "\(keyboard.vendorID)-\(keyboard.productID)-0",
                vendorID: keyboard.vendorID,
                productID: keyboard.productID,
                keyboardType: 40,
                keyboardTypeName: "ANSI"
            )
        }
    }

    private func parseConfiguredKeyboards(_ identifiers: [String]) -> [KeyboardInfo] {
        identifiers.compactMap { identifier in
            let parts = identifier.split(separator: "-")
            guard parts.count == 3,
                  let vendorID = Int(parts[0]),
                  let productID = Int(parts[1]) else {
                return nil
            }

            return KeyboardInfo(
                identifier: identifier,
                vendorID: vendorID,
                productID: productID,
                keyboardType: 40,
                keyboardTypeName: "ANSI"
            )
        }
    }

    private func isKeyboardConfigured(_ keyboard: KeyboardInfo) -> Bool {
        keyboardManager.configuredKeyboards?.contains(keyboard.identifier) ?? false
    }
}

// MARK: - Keyboard Section

struct KeyboardSection<Content: View>: View {
    let title: String
    let subtitle: String
    let icon: String
    let iconColor: Color
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(iconColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            VStack(spacing: 8) {
                content
            }
        }
    }
}

// MARK: - Keyboard Row

struct KeyboardRow: View {
    let keyboard: KeyboardInfo
    let isConfigured: Bool

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(nsColor: .controlBackgroundColor))
                    .frame(width: 40, height: 40)

                Image(systemName: "keyboard")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
            }

            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(keyboard.displayName)
                    .font(.body)
                    .fontWeight(.medium)

                Text(keyboard.identifier)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fontDesign(.monospaced)
            }

            Spacer()

            // Type Badge
            Text(keyboard.keyboardTypeName)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(6)

            // Status
            if isConfigured {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .help(Text(L("Configured in plist")))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isHovering ? Color(nsColor: .controlBackgroundColor) : Color.clear)
        )
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

// MARK: - Empty State

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "keyboard.badge.ellipsis")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            VStack(spacing: 4) {
                Text(L("No Keyboards Found"))
                    .font(.headline)

                Text(L("Click \"Detect\" to scan for connected USB keyboards"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(12)
    }
}

// MARK: - Info Card

struct InfoCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.blue)
                Text(L("Keyboard Type Reference"))
                    .font(.headline)
            }

            VStack(alignment: .leading, spacing: 6) {
                TypeInfoRow(code: "40", name: "ANSI", description: L("US / American layout"))
                TypeInfoRow(code: "41", name: "ISO", description: L("European layout"))
                TypeInfoRow(code: "42", name: "JIS", description: L("Japanese layout"))
            }
        }
        .padding(16)
        .background(Color.blue.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
        )
    }
}

struct TypeInfoRow: View {
    let code: String
    let name: String
    let description: String

    var body: some View {
        HStack {
            Text(code)
                .font(.caption)
                .fontDesign(.monospaced)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(4)

            Text(name)
                .fontWeight(.medium)

            Text("— \(description)")
                .foregroundColor(.secondary)
        }
        .font(.callout)
    }
}

// MARK: - USB Keyboard Detector (Public for KeyboardListView)

struct USBKeyboardDetector {
    static func detectConnectedKeyboards() -> [(vendorID: Int, productID: Int)] {
        var keyboards: [(vendorID: Int, productID: Int)] = []

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/system_profiler")
        process.arguments = ["SPUSBDataType", "-json"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            defer { try? pipe.fileHandleForReading.close() }

            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let usbData = json["SPUSBDataType"] as? [[String: Any]] {
                keyboards = parseUSBDevices(usbData)
            }
        } catch {
            // Silently continue with empty array
        }

        return keyboards
    }

    static func parseUSBDevices(_ devices: [[String: Any]]) -> [(vendorID: Int, productID: Int)] {
        var keyboards: [(vendorID: Int, productID: Int)] = []

        for device in devices {
            // Recursively check nested items
            if let items = device["_items"] as? [[String: Any]] {
                keyboards.append(contentsOf: parseUSBDevices(items))
            }

            // Look for keyboard devices
            if let name = device["_name"] as? String,
               name.lowercased().contains("keyboard") {
                if let productIDStr = device["product_id"] as? String,
                   let vendorIDStr = device["vendor_id"] as? String {
                    // Convert hex strings (0x...) to integers
                    let productID = Int(productIDStr.replacingOccurrences(of: "0x", with: ""), radix: 16) ?? 0
                    let vendorID = Int(vendorIDStr.replacingOccurrences(of: "0x", with: ""), radix: 16) ?? 0

                    if productID > 0 && vendorID > 0 {
                        keyboards.append((vendorID: vendorID, productID: productID))
                    }
                }
            }
        }

        return keyboards
    }
}

extension USBKeyboardDetector: USBDetectorProtocol {}
