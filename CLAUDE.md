macos-app, swift, speech-recognition, menu-bar-app, accessibility

- Native macOS menu bar application for system-wide voice-to-text input
- Built with Swift and SwiftUI targeting macOS 13.0+
- Uses Apple Speech Recognition framework for local speech-to-text transcription
- Global hotkey (Option + Space) triggers recording via Carbon API
- Text insertion via macOS Accessibility API simulates keyboard input
- Requires microphone, speech recognition, and accessibility permissions
- Menu bar app runs as LSUIElement (no dock icon, persistent in menu bar)
- Main components:
  - AppDelegate.swift: Menu bar orchestration and recording lifecycle
  - SpeechRecognizer.swift: AVAudioEngine + SFSpeechRecognizer integration
  - HotkeyManager.swift: Carbon-based global hotkey registration
  - TextInserter.swift: CGEvent-based text insertion (typing + clipboard methods)
- Two text insertion strategies: character simulation (default) and clipboard paste (faster for long text)
- All processing happens locally - no external API calls or data transmission
- Inspired by wisprflow.ai but fully open-source and privacy-focused
