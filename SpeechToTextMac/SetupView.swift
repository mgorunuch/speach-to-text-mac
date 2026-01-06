import SwiftUI
import AVFoundation
import ApplicationServices

struct SetupView: View {
    @StateObject private var viewModel = SetupViewModel()

    var body: some View {
        ZStack {
            // Background
            Color(red: 0.2, green: 0.2, blue: 0.2)
                .opacity(0.95)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack(spacing: 12) {
                    Image(systemName: "waveform.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.tint)
                        .symbolRenderingMode(.hierarchical)

                    Text("Voice to Text")
                        .font(.system(size: 24, weight: .bold))
                }
                .padding(.top, 24)
                .padding(.bottom, 16)

            // Status Banner
            if viewModel.isAllSetUp {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.title2)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Ready to Go!")
                            .font(.headline)
                        Text("Press F13 to start recording")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding()
                .background(Color.green.opacity(0.1))
            } else {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                        .font(.title2)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Setup Required")
                            .font(.headline)
                        Text("Enable permissions to continue")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding()
                .background(Color.orange.opacity(0.1))
            }

            Divider()

            // Main Form
            Form {
                // Permissions Section
                Section {
                    NativePermissionRow(
                        title: "Microphone",
                        icon: "mic.fill",
                        iconColor: .pink,
                        status: viewModel.microphonePermission,
                        action: viewModel.requestMicrophonePermission
                    )

                    NativePermissionRow(
                        title: "Accessibility",
                        icon: "hand.raised.fill",
                        iconColor: .blue,
                        status: viewModel.accessibilityPermission,
                        action: viewModel.openAccessibilityPreferences
                    )
                } header: {
                    Label("Permissions", systemImage: "lock.shield.fill")
                }

                // Audio Input Section
                Section {
                    Picker("Audio Device", selection: Binding(
                        get: { viewModel.selectedDeviceID ?? 0 },
                        set: { viewModel.selectedDeviceID = $0 }
                    )) {
                        ForEach(viewModel.audioDevices, id: \.id) { device in
                            Text(device.name + (device.isDefault ? " (Default)" : ""))
                                .tag(device.id)
                        }
                    }
                    .onChange(of: viewModel.selectedDeviceID) { newValue in
                        if let deviceID = newValue {
                            viewModel.savePreferredDevice(deviceID)
                        }
                    }

                    if let deviceName = viewModel.selectedDeviceName {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.caption)
                            Text("Using: \(deviceName)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Label("Audio Input", systemImage: "speaker.wave.3.fill")
                }

                // Speech Provider Section
                Section {
                    Picker("Provider", selection: $viewModel.selectedProvider) {
                        ForEach(SpeechProvider.allCases, id: \.self) { provider in
                            Text(provider.rawValue).tag(provider)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: viewModel.selectedProvider) { _ in
                        viewModel.saveSettings()
                    }

                    // OpenAI API Key
                    if viewModel.selectedProvider == .openai {
                        SecureField("OpenAI API Key", text: $viewModel.openAIKey, prompt: Text("sk-..."))
                            .onChange(of: viewModel.openAIKey) { _ in
                                viewModel.saveSettings()
                            }

                        Link("Get API Key", destination: URL(string: "https://platform.openai.com/api-keys")!)
                            .font(.caption)
                    }

                    // Groq API Key
                    if viewModel.selectedProvider == .groq {
                        SecureField("Groq API Key", text: $viewModel.groqKey, prompt: Text("gsk_..."))
                            .onChange(of: viewModel.groqKey) { _ in
                                viewModel.saveSettings()
                            }

                        Link("Get API Key", destination: URL(string: "https://console.groq.com/keys")!)
                            .font(.caption)
                    }

                    // Local Whisper info
                    if viewModel.selectedProvider == .local {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.shield.fill")
                                .foregroundStyle(.green)
                                .font(.caption)
                            Text("Processes audio locally on your device")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Label("Speech Provider", systemImage: "cpu.fill")
                }
            }
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)

            Divider()

                // Footer Buttons
                HStack {
                    Button("Refresh") {
                        viewModel.refresh()
                    }

                    Spacer()

                    Button("Done") {
                        NSApplication.shared.keyWindow?.close()
                    }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
        }
        .frame(width: 520, height: 650)
        .onAppear {
            viewModel.refresh()
        }
    }
}

struct NativePermissionRow: View {
    let title: String
    let icon: String
    let iconColor: Color
    let status: PermissionStatus
    let action: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(iconColor)
                .font(.title3)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)

                switch status {
                case .granted:
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                        Text("Enabled")
                            .font(.caption)
                    }
                    .foregroundStyle(.green)

                case .denied:
                    Text("Not enabled")
                        .font(.caption)
                        .foregroundStyle(.orange)

                case .notDetermined:
                    Text("Not requested")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if status != .granted {
                Button(status == .notDetermined ? "Request" : "Enable") {
                    action()
                }
                .buttonStyle(.bordered)
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
    @Published var selectedProvider: SpeechProvider = AppSettings.shared.provider
    @Published var openAIKey: String = AppSettings.shared.openAIKey
    @Published var groqKey: String = AppSettings.shared.groqKey

    var isAllSetUp: Bool {
        let permissionsGranted = microphonePermission == .granted && accessibilityPermission == .granted && selectedDeviceID != nil
        let providerConfigured = AppSettings.shared.isProviderConfigured(selectedProvider)
        return permissionsGranted && providerConfigured
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

    func saveSettings() {
        AppSettings.shared.provider = selectedProvider
        AppSettings.shared.openAIKey = openAIKey
        AppSettings.shared.groqKey = groqKey
    }
}

#Preview {
    SetupView()
}
