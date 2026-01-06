import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    var hotkeyManager: HotkeyManager?
    var whisperRecognizer: WhisperRecognizer?
    var isRecording = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon
        NSApp.setActivationPolicy(.accessory)

        // Create menu bar item
        setupMenuBar()

        // Initialize components
        whisperRecognizer = WhisperRecognizer()
        hotkeyManager = HotkeyManager()

        // Set up global hotkey (F13)
        hotkeyManager?.registerHotkey { [weak self] in
            self?.toggleRecording()
        }

        // Request permissions
        requestPermissions()
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

        // Show setup window on first launch
        if !UserDefaults.standard.bool(forKey: "hasCompletedSetup") {
            openSettings()
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
        print("🎙️ Recording started - Press F13 to stop")

        whisperRecognizer?.startRecording { [weak self] result in
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
        whisperRecognizer?.stopRecording()
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
        window.title = "Setup"
        window.styleMask = [.titled, .closable]
        window.center()
        window.makeKeyAndOrderFront(nil)
        window.level = .floating

        // Mark as completed after showing once
        UserDefaults.standard.set(true, forKey: "hasCompletedSetup")
    }

    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }

    func requestPermissions() {
        // Request microphone permission
        whisperRecognizer?.requestPermission()

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
