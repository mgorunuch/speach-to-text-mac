import SwiftUI
import Carbon

struct HotkeyRecorderView: View {
    @Binding var hotkey: HotkeyConfiguration
    @State private var isRecording = false
    let onHotkeyChanged: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Text("Global Hotkey")
                .font(.body)

            Spacer()

            Button(action: {
                isRecording = true
            }) {
                HStack(spacing: 8) {
                    if isRecording {
                        Text("Press key combination...")
                            .foregroundStyle(.orange)
                    } else {
                        Text(hotkey.displayString)
                            .fontWeight(.medium)
                    }
                    Image(systemName: isRecording ? "keyboard.badge.ellipsis" : "keyboard")
                        .foregroundStyle(isRecording ? .orange : .secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isRecording ? Color.orange.opacity(0.1) : Color.secondary.opacity(0.1))
                .cornerRadius(6)
            }
            .buttonStyle(.plain)
            .background(HotkeyEventView(isRecording: $isRecording, hotkey: $hotkey, onHotkeyChanged: onHotkeyChanged))
        }
    }
}

struct HotkeyEventView: NSViewRepresentable {
    @Binding var isRecording: Bool
    @Binding var hotkey: HotkeyConfiguration
    let onHotkeyChanged: () -> Void

    func makeNSView(context: Context) -> NSView {
        let view = KeyCaptureView()
        view.onKeyCaptured = { keyCode, modifiers in
            if isRecording {
                hotkey = HotkeyConfiguration(keyCode: keyCode, modifiers: modifiers)
                isRecording = false
                onHotkeyChanged()
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        if let captureView = nsView as? KeyCaptureView {
            captureView.isCapturing = isRecording
        }
    }
}

class KeyCaptureView: NSView {
    var isCapturing = false
    var onKeyCaptured: ((UInt32, UInt32) -> Void)?
    private var localMonitor: Any?

    override var acceptsFirstResponder: Bool { true }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        becomeFirstResponder()
        setupMonitor()
    }

    private func setupMonitor() {
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self, self.isCapturing else { return event }

            let keyCode = UInt32(event.keyCode)
            var modifiers: UInt32 = 0

            if event.modifierFlags.contains(.command) {
                modifiers |= UInt32(cmdKey)
            }
            if event.modifierFlags.contains(.option) {
                modifiers |= UInt32(optionKey)
            }
            if event.modifierFlags.contains(.control) {
                modifiers |= UInt32(controlKey)
            }
            if event.modifierFlags.contains(.shift) {
                modifiers |= UInt32(shiftKey)
            }

            self.onKeyCaptured?(keyCode, modifiers)
            return nil
        }
    }

    deinit {
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}
