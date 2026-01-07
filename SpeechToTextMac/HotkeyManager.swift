import Cocoa
import Carbon

class HotkeyManager {
    private var eventHandler: EventHandlerRef?
    private var hotKeyRef: EventHotKeyRef?
    private var callback: (() -> Void)?

    func registerHotkey(config: HotkeyConfiguration, callback: @escaping () -> Void) {
        self.callback = callback

        // Unregister existing hotkey if any
        unregisterHotkey()

        // Register hotkey
        let hotkeyID = EventHotKeyID(signature: UTGetOSTypeFromString("WSPR" as CFString), id: 1)
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

        // Install event handler
        InstallEventHandler(GetApplicationEventTarget(), { _, event, userData in
            let manager = Unmanaged<HotkeyManager>.fromOpaque(userData!).takeUnretainedValue()
            manager.callback?()
            return noErr
        }, 1, &eventType, Unmanaged.passUnretained(self).toOpaque(), &eventHandler)

        // Register hotkey with custom configuration
        RegisterEventHotKey(config.keyCode, config.modifiers, hotkeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
    }

    func unregisterHotkey() {
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
    }

    deinit {
        unregisterHotkey()
        if let eventHandler = eventHandler {
            RemoveEventHandler(eventHandler)
        }
    }
}
