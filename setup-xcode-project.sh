#!/bin/bash
# Script to set up a proper Xcode project for SpeechToTextMac

set -e

PROJECT_NAME="SpeechToTextMac"
PROJECT_DIR="/Users/mgorunuch/projects/speech-to-text-mac"
XCODE_PROJECT="$PROJECT_DIR/$PROJECT_NAME.xcodeproj"

echo "🎙️  Setting up Xcode project for SpeechToTextMac..."

# Check if xcodeproj already exists
if [ -d "$XCODE_PROJECT" ]; then
    echo "⚠️  Xcode project already exists. Opening it..."
    open "$XCODE_PROJECT"
    exit 0
fi

echo ""
echo "📝 Please create the Xcode project manually:"
echo ""
echo "1. Open Xcode"
echo "2. File → New → Project"
echo "3. Choose 'macOS' → 'App'"
echo "4. Settings:"
echo "   - Product Name: SpeechToTextMac"
echo "   - Interface: SwiftUI"
echo "   - Language: Swift"
echo "   - Save in: $PROJECT_DIR"
echo ""
echo "5. Delete the default files Xcode creates:"
echo "   - ContentView.swift"
echo "   - SpeechToTextMacApp.swift (Xcode's version)"
echo ""
echo "6. Add our files to the project:"
echo "   - Right-click on SpeechToTextMac folder in sidebar"
echo "   - 'Add Files to SpeechToTextMac...'"
echo "   - Select all .swift files from SpeechToTextMac/ folder"
echo "   - Make sure 'Copy items if needed' is unchecked"
echo "   - Click 'Add'"
echo ""
echo "7. Replace Info.plist:"
echo "   - Delete Xcode's Info.plist"
echo "   - Add our SpeechToTextMac/Info.plist"
echo ""
echo "8. Build and Run (Cmd+R)"
echo ""
echo "Or run: open -a Xcode"
echo "Then follow the steps above."
