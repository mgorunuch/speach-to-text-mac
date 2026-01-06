# 🚀 Quick Start Guide

## Method 1: Create Xcode Project Manually (5 minutes)

Xcode is now open. Follow these steps:

### Step 1: Create New Project
1. In Xcode, click **File → New → Project** (or `Cmd+Shift+N`)
2. Choose **macOS** tab at the top
3. Select **App** template
4. Click **Next**

### Step 2: Configure Project
- **Product Name**: `SpeechToTextMac`
- **Team**: Select your team (or leave empty for now)
- **Organization Identifier**: `com.yourname` (or your domain)
- **Interface**: Choose **SwiftUI**
- **Language**: **Swift**
- **Storage**: Core Data ❌ (unchecked)
- **Tests**: ❌ (unchecked)
- Click **Next**

### Step 3: Save Location
- Navigate to: `/Users/mgorunuch/projects/speech-to-text-mac`
- **IMPORTANT**: Uncheck "Create Git repository" (we already have one)
- Click **Create**

### Step 4: Clean Up Default Files
Xcode created some default files we don't need. In the Project Navigator (left sidebar):

1. **Delete these files** (select and press Delete → Move to Trash):
   - `ContentView.swift`
   - The default `SpeechToTextMacApp.swift` (Xcode's version)
   - `Assets.xcassets` (optional, we don't need it yet)

### Step 5: Add Our Swift Files
1. Right-click on the **SpeechToTextMac** folder (blue icon) in the sidebar
2. Select **Add Files to "SpeechToTextMac"...**
3. Navigate to the `SpeechToTextMac` folder in Finder
4. Select ALL `.swift` files:
   - `SpeechToTextMacApp.swift`
   - `AppDelegate.swift`
   - `SpeechRecognizer.swift`
   - `HotkeyManager.swift`
   - `TextInserter.swift`
5. **IMPORTANT**: Make sure these options are set:
   - ✅ **Copy items if needed** (UNCHECKED - we want to reference, not copy)
   - ✅ **Create groups** (selected)
   - ✅ **Add to targets: SpeechToTextMac** (checked)
6. Click **Add**

### Step 6: Configure Info.plist
1. In the Project Navigator, find and select the Xcode-created `Info.plist`
2. Delete it (Move to Trash)
3. Right-click on **SpeechToTextMac** folder → **Add Files to "SpeechToTextMac"...**
4. Select our `SpeechToTextMac/Info.plist`
5. Make sure **Copy items if needed is UNCHECKED**
6. Click **Add**
7. Click on the **SpeechToTextMac** project (blue icon at the very top)
8. Select the **SpeechToTextMac** target
9. Go to **Build Settings** tab
10. Search for "Info.plist"
11. Set **Info.plist File** to: `SpeechToTextMac/Info.plist`

### Step 7: Build & Run! 🎉
1. Press **Cmd + B** to build
2. Press **Cmd + R** to run
3. Grant permissions when prompted:
   - Microphone ✅
   - Speech Recognition ✅
   - Accessibility (go to System Preferences) ✅

### Step 8: Test It
- Look for the microphone 🎤 icon in your menu bar
- Press **Option + Space** to start recording
- Speak something
- Press **Option + Space** again to stop
- The text should appear in your focused text field!

---

## Method 2: Use XcodeGen (Advanced)

If you have XcodeGen installed:

```bash
brew install xcodegen
cd /Users/mgorunuch/projects/speech-to-text-mac
xcodegen generate
open SpeechToTextMac.xcodeproj
```

---

## Troubleshooting

### "No such module 'Cocoa'" error
- This happens with Swift Package Manager. Use Method 1 to create a proper Xcode project.

### App doesn't appear in menu bar
- Make sure you're running the app (not just building)
- Check Console for errors

### Text not inserting
- Go to **System Preferences → Privacy & Security → Accessibility**
- Find **SpeechToTextMac** and enable it
- Restart the app

### Microphone not working
- Go to **System Preferences → Privacy & Security → Microphone**
- Enable **SpeechToTextMac**

---

## Next Steps

Once the app is running:
- Customize the hotkey in `HotkeyManager.swift`
- Try the faster clipboard insertion method in `TextInserter.swift`
- Add AI text polishing features
- Create a custom app icon

Enjoy your new voice-to-text superpower! 🎙️✨
