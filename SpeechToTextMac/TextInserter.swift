import Cocoa
import ApplicationServices
import Carbon

class TextInserter {
    static func insertText(_ text: String) {
        // Use Accessibility API to insert text into focused application
        DispatchQueue.main.async {
            // Method 1: Simulate typing using CGEvent
            simulateTyping(text)
        }
    }

    private static func simulateTyping(_ text: String) {
        // Create keyboard events to type the text
        let source = CGEventSource(stateID: .combinedSessionState)

        for char in text {
            let keyCode = CGKeyCode(0) // Virtual key code

            // Convert character to UniChar array
            var unicodeChars = Array(char.utf16)

            // Key down event
            if let keyDownEvent = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true) {
                keyDownEvent.keyboardSetUnicodeString(stringLength: unicodeChars.count, unicodeString: &unicodeChars)
                keyDownEvent.post(tap: .cghidEventTap)
            }

            // Key up event
            if let keyUpEvent = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false) {
                keyUpEvent.keyboardSetUnicodeString(stringLength: unicodeChars.count, unicodeString: &unicodeChars)
                keyUpEvent.post(tap: .cghidEventTap)
            }

            // Small delay between characters for reliability
            usleep(1000) // 1ms
        }
    }

    // Alternative method using pasteboard (more reliable for longer text)
    static func insertTextViaPasteboard(_ text: String) {
        print("📋 Attempting to paste text: \"\(text)\"")

        // Check accessibility permissions
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
        let hasAccessibility = AXIsProcessTrustedWithOptions(options)

        print("🔐 Accessibility permission: \(hasAccessibility ? "✅ GRANTED" : "❌ DENIED")")

        // Check if we can create CGEvents (indicates Input Monitoring permission)
        let canCreateEvents = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true) != nil
        print("⌨️  Input Monitoring (CGEvent): \(canCreateEvents ? "✅ CAN CREATE" : "❌ BLOCKED")")

        let hasPermission = hasAccessibility && canCreateEvents

        if !hasPermission {
            print("❌ ACCESSIBILITY PERMISSION DENIED!")
            print("⚠️  Go to System Preferences → Privacy & Security → Accessibility")
            print("⚠️  Enable SpeechToTextMac to allow text insertion")
            print("⚠️  Note: When running from Xcode, you may need to grant permission to the")
            print("⚠️  DerivedData build location each time you rebuild")
            return
        }

        let pasteboard = NSPasteboard.general
        let previousContents = pasteboard.string(forType: .string)

        // Copy text to clipboard
        pasteboard.clearContents()
        let success = pasteboard.setString(text, forType: .string)

        if !success {
            print("❌ Failed to copy text to clipboard")
            return
        }

        print("✅ Text copied to clipboard: \"\(text)\"")

        // Verify clipboard contents
        if let clipboardText = pasteboard.string(forType: .string) {
            print("✅ Clipboard verified: \"\(clipboardText)\"")
        } else {
            print("❌ Clipboard verification failed!")
            return
        }

        // Wait a bit for clipboard to be ready
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            guard let source = CGEventSource(stateID: .combinedSessionState) else {
                print("❌ Failed to create CGEventSource")
                return
            }

            print("⌨️  Sending Cmd+V...")

            // Create Cmd+V key press
            guard let vKeyDown = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: true),
                  let vKeyUp = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: false) else {
                print("❌ Failed to create key events")
                return
            }

            // Set Command flag
            vKeyDown.flags = .maskCommand
            vKeyUp.flags = .maskCommand

            // Post the events
            vKeyDown.post(tap: .cghidEventTap)
            usleep(10000) // 10ms delay between key down and up
            vKeyUp.post(tap: .cghidEventTap)

            print("✅ Paste command sent (Cmd+V)")

            // Restore previous clipboard contents after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if let previous = previousContents {
                    pasteboard.clearContents()
                    pasteboard.setString(previous, forType: .string)
                    print("♻️  Clipboard restored")
                }
            }
        }
    }
}
