# 🎙️ SpeechToTextMac - Voice to Text for macOS

A native macOS menu bar app that transcribes your speech and inserts it into any text field, similar to [wisprflow.ai](https://wisprflow.ai/).

## Features

- **System-wide voice input**: Works in any macOS application
- **Global hotkey**: Press `Option + Space` to start/stop recording
- **Menu bar app**: Lightweight, always accessible from the menu bar
- **Real-time transcription**: Uses Apple's Speech Recognition framework
- **Automatic text insertion**: Seamlessly inserts transcribed text into any focused text field

## Requirements

- macOS 13.0 or later
- Xcode 15.0 or later
- Microphone access
- Accessibility permissions

## Installation

### Option 1: Build from Source with Xcode

1. Clone this repository:
   ```bash
   cd /Users/mgorunuch/projects/speech-to-text-mac
   ```

2. Open the project in Xcode:
   ```bash
   open SpeechToTextMac.xcodeproj
   ```

   Or create a new Xcode project:
   - Open Xcode
   - Create a new macOS App project
   - Name it "SpeechToTextMac"
   - Choose SwiftUI for the interface
   - Add all `.swift` files from the `SpeechToTextMac/` directory
   - Replace `Info.plist` with the provided one

3. Build and run the project (`Cmd + R`)

### Option 2: Build with Swift Package Manager

```bash
swift build -c release
.build/release/SpeechToTextMac
```

## Setup

After launching the app for the first time, you'll need to grant permissions:

### 1. Microphone Permission
- The app will automatically request microphone access
- Click "OK" when prompted

### 2. Speech Recognition Permission
- The app will request speech recognition access
- Click "OK" to allow

### 3. Accessibility Permission (Required for text insertion)
- Go to **System Preferences** → **Privacy & Security** → **Accessibility**
- Click the lock icon to make changes
- Find "SpeechToTextMac" in the list and enable it
- If not listed, click "+" and add the SpeechToTextMac app

## Usage

1. **Start the app**: SpeechToTextMac will appear in your menu bar (microphone icon)

2. **Activate recording**:
   - Press `Option + Space` (global hotkey), OR
   - Click the menu bar icon and select "Start Recording"

3. **Speak**: Talk naturally - the app will transcribe your speech

4. **Stop recording**:
   - Press `Option + Space` again, OR
   - The app will auto-stop when you pause

5. **Text insertion**: The transcribed text will be automatically inserted into your focused text field

## Menu Bar Options

- **Start Recording**: Begin voice transcription
- **Settings**: Configure app preferences (coming soon)
- **Quit**: Exit the application

## How It Works

1. **Global Hotkey**: Carbon API monitors for `Option + Space` system-wide
2. **Speech Recognition**: Apple's Speech framework transcribes audio in real-time
3. **Text Insertion**: Accessibility API simulates keyboard input to insert text
4. **Menu Bar Integration**: NSStatusItem provides persistent menu bar presence

## Customization

### Change the Hotkey

Edit `HotkeyManager.swift:15` to change the hotkey combination:

```swift
// Current: Option + Space
let keyCode = UInt32(kVK_Space)
let modifiers = UInt32(optionKey)

// Example: Command + Shift + R
let keyCode = UInt32(kVK_ANSI_R)
let modifiers = UInt32(cmdKey | shiftKey)
```

### Change Text Insertion Method

Edit `AppDelegate.swift:56` to switch between typing simulation and clipboard paste:

```swift
// Current: Character-by-character typing
TextInserter.insertText(text)

// Alternative: Faster clipboard paste (recommended for longer text)
TextInserter.insertTextViaPasteboard(text)
```

## Troubleshooting

### Text not being inserted
- Ensure Accessibility permissions are enabled in System Preferences
- Try using the clipboard method: `TextInserter.insertTextViaPasteboard(text)`

### Hotkey not working
- Check that no other app is using `Option + Space`
- Restart the app after granting permissions

### Speech recognition not working
- Verify microphone permissions in System Preferences → Privacy & Security
- Check that Speech Recognition is enabled for the app
- Ensure your Mac has internet connection (first-time setup requires download)

## Architecture

```
SpeechToTextMac/
├── SpeechToTextMacApp.swift       # SwiftUI app entry point
├── AppDelegate.swift        # Menu bar app + orchestration
├── SpeechRecognizer.swift   # Speech-to-text engine
├── HotkeyManager.swift      # Global hotkey listener
├── TextInserter.swift       # Text injection via Accessibility API
└── Info.plist               # App permissions & config
```

## Future Enhancements

- [ ] AI-powered text editing (remove filler words, improve grammar)
- [ ] Multi-language support
- [ ] Custom vocabulary/dictionary
- [ ] Text snippets/templates
- [ ] Context-aware formatting
- [ ] Settings UI
- [ ] Auto-start on login

## Privacy

All speech processing happens **locally on your Mac** using Apple's Speech Recognition framework. No audio or text data is sent to external servers.

## License

MIT License - Feel free to modify and distribute

## Credits

Inspired by [wisprflow.ai](https://wisprflow.ai/)
