import Cocoa
import SwiftUI
import AVFoundation

class AppDelegate: NSObject, NSApplicationDelegate {
    enum RecordingState {
        case idle
        case recording
        case transcribing
    }

    var statusItem: NSStatusItem?
    var popover: NSPopover?
    var hotkeyManager: HotkeyManager?
    var recognizerManager: RecognizerManager?
    var isRecording = false
    var currentState: RecordingState = .idle
    private var escapeMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon
        NSApp.setActivationPolicy(.accessory)

        // Create menu bar item
        setupMenuBar()

        // Initialize components
        recognizerManager = RecognizerManager()
        hotkeyManager = HotkeyManager()

        // Set up global hotkey with user configuration
        registerHotkey()

        // Listen for hotkey changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(hotkeyDidChange),
            name: NSNotification.Name("HotkeyChanged"),
            object: nil
        )
    }

    func registerHotkey() {
        let config = AppSettings.shared.hotkey
        hotkeyManager?.registerHotkey(config: config) { [weak self] in
            self?.toggleRecording()
        }
    }

    @objc func hotkeyDidChange() {
        registerHotkey()
    }

    func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "mic.fill", accessibilityDescription: "Speech to Text Mac")
            button.action = #selector(togglePopover)
        }

        let menu = NSMenu()
        menu.delegate = self
        menu.addItem(NSMenuItem(title: "Start Recording", action: #selector(startRecording), keyEquivalent: "r"))
        menu.addItem(NSMenuItem.separator())

        // History submenu
        let historyItem = NSMenuItem(title: "History", action: nil, keyEquivalent: "")
        let historySubmenu = buildHistorySubmenu()
        historyItem.submenu = historySubmenu
        menu.addItem(historyItem)

        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Setup & Permissions", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))

        statusItem?.menu = menu

        // Show setup window if permissions are not granted or on first launch
        if !arePermissionsGranted() || !UserDefaults.standard.bool(forKey: "hasCompletedSetup") {
            // Delay to ensure UI is ready
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.openSettings()
            }
        }
    }

    @objc func togglePopover() {
        // Could show a popover with status/controls
    }

    @objc func startRecording() {
        toggleRecording()
    }

    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecordingSession()
        }
    }

    func startRecordingSession() {
        isRecording = true
        updateMenuBarStatus(.recording)
        startEscapeMonitor()
        FeedbackManager.shared.playFeedback(.recordingStarted)

        let provider = AppSettings.shared.provider
        let hotkey = AppSettings.shared.hotkey
        print("🎙️ Recording started - Press \(hotkey.displayString) to stop (Provider: \(provider.rawValue))")

        recognizerManager?.startRecording { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let text):
                print("✅ Transcription successful: \(text)")

                // Update to idle state and play completion sound
                self.updateMenuBarStatus(.idle)
                FeedbackManager.shared.playFeedback(.completed)

                // Save to history before inserting text
                let tempAudioURL = URL(fileURLWithPath: NSTemporaryDirectory() + "recording.wav")
                TranscriptHistoryManager.shared.save(
                    text: text,
                    provider: AppSettings.shared.provider,
                    audioURL: tempAudioURL
                )

                // Insert text into active application
                // Use clipboard method (more reliable)
                TextInserter.insertTextViaPasteboard(text)

            case .failure(let error):
                print("❌ Final error: \(error.localizedDescription)")
                self.updateMenuBarStatus(.idle)
                FeedbackManager.shared.playFeedback(.error)
            }
        }
    }

    func stopRecording() {
        print("⏹️ Recording stopped - Transcribing...")
        stopEscapeMonitor()
        isRecording = false
        updateMenuBarStatus(.transcribing)
        FeedbackManager.shared.playFeedback(.recordingStopped)
        recognizerManager?.stopRecording()
    }

    func cancelRecording() {
        guard currentState == .recording else { return }

        print("🚫 Recording cancelled by user")
        stopEscapeMonitor()
        isRecording = false
        updateMenuBarStatus(.idle)
        FeedbackManager.shared.playFeedback(.cancelled)
        recognizerManager?.cancelRecording()
    }

    private func startEscapeMonitor() {
        escapeMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { // Escape key
                DispatchQueue.main.async {
                    self?.cancelRecording()
                }
            }
        }
    }

    private func stopEscapeMonitor() {
        if let monitor = escapeMonitor {
            NSEvent.removeMonitor(monitor)
            escapeMonitor = nil
        }
    }

    func updateMenuBarStatus(_ state: RecordingState) {
        currentState = state

        if let button = statusItem?.button {
            let (iconName, title) = getStatusDisplay(for: state)

            button.image = NSImage(
                systemSymbolName: iconName,
                accessibilityDescription: title
            )
            button.title = state == .idle ? "" : " \(getStatusText(for: state))"
        }
    }

    func getStatusDisplay(for state: RecordingState) -> (String, String) {
        switch state {
        case .idle:
            return ("mic.fill", "Speech to Text Mac")
        case .recording:
            return ("mic.fill.badge.plus", "Recording...")
        case .transcribing:
            return ("waveform.badge.magnifyingglass", "Transcribing...")
        }
    }

    func getStatusText(for state: RecordingState) -> String {
        switch state {
        case .idle:
            return ""
        case .recording:
            return "🔴"
        case .transcribing:
            return "⏳"
        }
    }

    @objc func openSettings() {
        NSApp.activate(ignoringOtherApps: true)

        let setupView = SetupView()
        let hostingController = NSHostingController(rootView: setupView)

        let window = NSWindow(contentViewController: hostingController)
        window.title = ""
        window.styleMask = [.titled, .closable, .fullSizeContentView]
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = true
        window.center()
        window.makeKeyAndOrderFront(nil)
        window.level = .floating

        // Mark as completed after showing once
        UserDefaults.standard.set(true, forKey: "hasCompletedSetup")
    }

    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }

    func arePermissionsGranted() -> Bool {
        // Check microphone permission
        let microphoneGranted = AVCaptureDevice.authorizationStatus(for: .audio) == .authorized

        // Check accessibility permission
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
        let accessibilityGranted = AXIsProcessTrustedWithOptions(options)

        return microphoneGranted && accessibilityGranted
    }

    func requestPermissions() {
        // Request microphone permission
        recognizerManager?.requestPermission()

        // Show accessibility permission dialog
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options)

        if !accessEnabled {
            print("Please enable Accessibility permissions in System Preferences")
            let bundlePath = Bundle.main.bundlePath
            print("⚠️  Add this app to Accessibility:")
            print("📍 \(bundlePath)")

            // Open Finder to show the app
            let appURL = URL(fileURLWithPath: bundlePath)
            NSWorkspace.shared.activateFileViewerSelecting([appURL])
            print("📂 Opening Finder to app location...")
        }
    }

    private func buildHistorySubmenu() -> NSMenu {
        let submenu = NSMenu()
        let recentTranscripts = TranscriptHistoryManager.shared.getRecent(limit: 5)

        if recentTranscripts.isEmpty {
            let emptyItem = NSMenuItem(title: "No transcripts yet", action: nil, keyEquivalent: "")
            emptyItem.isEnabled = false
            submenu.addItem(emptyItem)
        } else {
            for record in recentTranscripts {
                let preview = String(record.text.prefix(50)) + (record.text.count > 50 ? "..." : "")
                let item = NSMenuItem(
                    title: "\(record.formattedDate) - \(preview)",
                    action: #selector(copyTranscript(_:)),
                    keyEquivalent: ""
                )
                item.representedObject = record.id
                submenu.addItem(item)
            }
        }

        submenu.addItem(NSMenuItem.separator())
        submenu.addItem(NSMenuItem(title: "View All...", action: #selector(openSettings), keyEquivalent: "h"))

        return submenu
    }

    @objc func copyTranscript(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? UUID else { return }
        let records = TranscriptHistoryManager.shared.getAll()
        guard let record = records.first(where: { $0.id == id }) else { return }

        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(record.text, forType: .string)
        print("📋 Copied transcript to clipboard")
    }

}

extension AppDelegate: NSMenuDelegate {
    func menuNeedsUpdate(_ menu: NSMenu) {
        if let historyItem = menu.items.first(where: { $0.title == "History" }) {
            historyItem.submenu = buildHistorySubmenu()
        }
    }
}
