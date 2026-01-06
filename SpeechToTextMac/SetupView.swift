import SwiftUI
import AVFoundation
import ApplicationServices

struct SetupView: View {
    @StateObject private var viewModel = SetupViewModel()

    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "mic.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.blue)

                Text("SpeechToTextMac Setup")
                    .font(.title)
                    .bold()

                Text("Press F13 to record, F13 to stop")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 20)

            Divider()

            // Permissions Status
            VStack(alignment: .leading, spacing: 16) {
                Text("Permissions")
                    .font(.headline)

                PermissionRow(
                    title: "Microphone",
                    icon: "mic.fill",
                    status: viewModel.microphonePermission,
                    action: viewModel.requestMicrophonePermission
                )

                PermissionRow(
                    title: "Accessibility",
                    icon: "hand.raised.fill",
                    status: viewModel.accessibilityPermission,
                    action: viewModel.openAccessibilityPreferences
                )
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)

            // Audio Device Selection
            VStack(alignment: .leading, spacing: 12) {
                Text("Microphone")
                    .font(.headline)

                Picker("Select Device", selection: Binding(
                    get: { viewModel.selectedDeviceID ?? 0 },
                    set: { viewModel.selectedDeviceID = $0 }
                )) {
                    ForEach(viewModel.audioDevices, id: \.id) { device in
                        HStack {
                            Text(device.name)
                            if device.isDefault {
                                Text("(Default)")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                        }
                        .tag(device.id)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: viewModel.selectedDeviceID) { newValue in
                    if let deviceID = newValue {
                        viewModel.savePreferredDevice(deviceID)
                    }
                }

                if let deviceName = viewModel.selectedDeviceName {
                    Text("✓ Using: \(deviceName)")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)

            // Status
            if viewModel.isAllSetUp {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("All set! Close this window and press F13 to start.")
                        .font(.subheadline)
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
            } else {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("Complete the steps above to get started")
                        .font(.subheadline)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }

            Spacer()

            // Footer
            HStack {
                Button("Refresh Status") {
                    viewModel.refresh()
                }

                Spacer()

                Button("Close") {
                    NSApplication.shared.keyWindow?.close()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding(.bottom, 16)
        }
        .padding()
        .frame(width: 450, height: 550)
        .onAppear {
            viewModel.refresh()
        }
    }
}

struct PermissionRow: View {
    let title: String
    let icon: String
    let status: PermissionStatus
    let action: () -> Void

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)

            Text(title)
                .frame(maxWidth: .infinity, alignment: .leading)

            switch status {
            case .granted:
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Granted")
                        .foregroundColor(.green)
                        .font(.caption)
                }

            case .denied:
                Button("Enable") {
                    action()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)

            case .notDetermined:
                Button("Request") {
                    action()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
    }
}

enum PermissionStatus {
    case granted
    case denied
    case notDetermined
}

struct AudioDevice: Identifiable {
    let id: UInt32
    let name: String
    let isDefault: Bool
}

@MainActor
class SetupViewModel: ObservableObject {
    @Published var microphonePermission: PermissionStatus = .notDetermined
    @Published var accessibilityPermission: PermissionStatus = .notDetermined
    @Published var audioDevices: [AudioDevice] = []
    @Published var selectedDeviceID: UInt32?

    var isAllSetUp: Bool {
        microphonePermission == .granted && accessibilityPermission == .granted && selectedDeviceID != nil
    }

    var selectedDeviceName: String? {
        guard let deviceID = selectedDeviceID else { return nil }
        return audioDevices.first(where: { $0.id == deviceID })?.name
    }

    func refresh() {
        checkMicrophonePermission()
        checkAccessibilityPermission()
        loadAudioDevices()
    }

    func checkMicrophonePermission() {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            microphonePermission = .granted
        case .denied, .restricted:
            microphonePermission = .denied
        case .notDetermined:
            microphonePermission = .notDetermined
        @unknown default:
            microphonePermission = .notDetermined
        }
    }

    func checkAccessibilityPermission() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
        let hasPermission = AXIsProcessTrustedWithOptions(options)
        accessibilityPermission = hasPermission ? .granted : .denied
    }

    func requestMicrophonePermission() {
        AVCaptureDevice.requestAccess(for: .audio) { _ in
            Task { @MainActor in
                self.checkMicrophonePermission()
            }
        }
    }

    func openAccessibilityPreferences() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }

    func loadAudioDevices() {
        #if os(macOS)
        var devices: [AudioDevice] = []

        // Get all devices
        var propertySize: UInt32 = 0
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &propertyAddress, 0, nil, &propertySize)

        let deviceCount = Int(propertySize) / MemoryLayout<AudioDeviceID>.size
        var deviceIDs = [AudioDeviceID](repeating: 0, count: deviceCount)

        AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &propertyAddress, 0, nil, &propertySize, &deviceIDs)

        // Get default device
        var defaultDeviceID = AudioDeviceID(0)
        var defaultSize: UInt32 = UInt32(MemoryLayout<AudioDeviceID>.size)
        var defaultInputAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &defaultInputAddress, 0, nil, &defaultSize, &defaultDeviceID)

        for deviceID in deviceIDs {
            // Check if it has input channels
            var streamAddress = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyStreamConfiguration,
                mScope: kAudioDevicePropertyScopeInput,
                mElement: 0
            )

            var streamSize: UInt32 = 0
            guard AudioObjectGetPropertyDataSize(deviceID, &streamAddress, 0, nil, &streamSize) == noErr else { continue }

            var bufferList = AudioBufferList()
            guard AudioObjectGetPropertyData(deviceID, &streamAddress, 0, nil, &streamSize, &bufferList) == noErr else { continue }

            if bufferList.mNumberBuffers > 0 {
                // Get device name
                var deviceName: CFString = "" as CFString
                var nameSize = UInt32(MemoryLayout<CFString>.size)
                var nameAddress = AudioObjectPropertyAddress(
                    mSelector: kAudioDevicePropertyDeviceNameCFString,
                    mScope: kAudioObjectPropertyScopeGlobal,
                    mElement: kAudioObjectPropertyElementMain
                )

                if AudioObjectGetPropertyData(deviceID, &nameAddress, 0, nil, &nameSize, &deviceName) == noErr {
                    devices.append(AudioDevice(
                        id: deviceID,
                        name: deviceName as String,
                        isDefault: deviceID == defaultDeviceID
                    ))
                }
            }
        }

        audioDevices = devices.sorted { $0.isDefault && !$1.isDefault }

        // Load saved preference or use default
        if let savedID = UserDefaults.standard.object(forKey: "preferredDeviceID") as? UInt32 {
            selectedDeviceID = savedID
        } else {
            selectedDeviceID = defaultDeviceID
        }
        #endif
    }

    func savePreferredDevice(_ deviceID: UInt32) {
        UserDefaults.standard.set(deviceID, forKey: "preferredDeviceID")
        print("💾 Saved preferred device: \(deviceID)")
    }
}

#Preview {
    SetupView()
}
