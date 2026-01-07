# Building and Installing SpeechToTextMac

## Custom App Icon

The app uses a custom icon (`AppIcon.icns`). To regenerate it from the source PNG:

```bash
./create-icon.sh
```

This will convert `~/Downloads/stt-favicon.png` to the required `.icns` format with all necessary sizes.

## Quick Install (Recommended)

Run the install script to build and install in one step:

```bash
./install.sh
```

This will:
1. Build the app in release mode
2. Create a proper .app bundle with custom icon
3. Install it to `/Applications/SpeechToTextMac.app`

## Manual Build

If you just want to build without installing:

```bash
./build-app.sh
```

This creates `SpeechToTextMac.app` in the current directory.

## Manual Installation

After building, you can manually install:

```bash
cp -r SpeechToTextMac.app /Applications/
```

Or just drag `SpeechToTextMac.app` to your Applications folder in Finder.

## Running the App

### From Terminal:
```bash
open /Applications/SpeechToTextMac.app
```

### From Finder:
1. Open your Applications folder
2. Double-click `SpeechToTextMac`

### From Spotlight:
1. Press `Cmd + Space`
2. Type "SpeechToTextMac"
3. Press Enter

## First Launch

On first launch, you'll need to:
1. Grant **Microphone** permission
2. Grant **Accessibility** permission (for text insertion)
3. Configure your **Speech Provider** (Local Whisper, OpenAI, or Groq)
4. Set your **Global Hotkey** (default: ⌥Space)

## Development Build

For development and testing:

```bash
swift build
.build/debug/SpeechToTextMac
```

## Release Build (Command Line)

For a command-line release build without creating .app:

```bash
swift build -c release
.build/release/SpeechToTextMac
```

## Uninstalling

```bash
rm -rf /Applications/SpeechToTextMac.app
```

## Troubleshooting

### App won't open
- Make sure you've granted all required permissions
- Check Console.app for error messages
- Try rebuilding: `./build-app.sh`

### "App is damaged" message
Run this to remove quarantine attribute:
```bash
xattr -cr /Applications/SpeechToTextMac.app
```

### Permissions not working
- Open System Settings → Privacy & Security
- Manually add SpeechToTextMac to:
  - Microphone
  - Accessibility
