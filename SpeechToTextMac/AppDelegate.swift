import Cocoa
import SwiftUI
import AVFoundation

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    var hotkeyManager: HotkeyManager?
    var recognizerManager: RecognizerManager?
    var isRecording = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon
        NSApp.setActivationPolicy(.accessory)

        // Create menu bar item
        setupMenuBar()

        // Initialize components
        recognizerManager = RecognizerManager()
        hotkeyManager = HotkeyManager()

        // Set up global hotkey (F13)
        hotkeyManager?.registerHotkey { [weak self] in
            self?.toggleRecording()
        }
    }

    func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "mic.fill", accessibilityDescription: "Speech to Text Mac")
            button.action = #selector(togglePopover)
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Start Recording", action: #selector(startRecording), keyEquivalent: "r"))
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
        updateMenuBarIcon(recording: true)

        let provider = AppSettings.shared.provider
        print("🎙️ Recording started - Press F13 to stop (Provider: \(provider.rawValue))")

        recognizerManager?.startRecording { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let text):
                print("✅ Transcription successful: \(text)")
                // Insert text into active application
                // Use clipboard method (more reliable)
                TextInserter.insertTextViaPasteboard(text)

            case .failure(let error):
                print("❌ Final error: \(error.localizedDescription)")
            }
        }
    }

    func stopRecording() {
        print("⏹️ Recording stopped")
        isRecording = false
        updateMenuBarIcon(recording: false)
        recognizerManager?.stopRecording()
    }

    func updateMenuBarIcon(recording: Bool) {
        if let button = statusItem?.button {
            button.image = NSImage(
                systemSymbolName: recording ? "mic.fill.badge.plus" : "mic.fill",
                accessibilityDescription: recording ? "Recording" : "Speech to Text Mac"
            )
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
}
