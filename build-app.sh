#!/bin/bash

# Build script to create a proper macOS .app bundle

set -e

echo "🔨 Building SpeechToTextMac.app..."

# Clean previous builds
echo "🧹 Cleaning previous builds..."
rm -rf .build/release
rm -rf SpeechToTextMac.app

# Build in release mode
echo "📦 Building release binary..."
swift build -c release

# Create app bundle structure
echo "📁 Creating app bundle structure..."
mkdir -p SpeechToTextMac.app/Contents/MacOS
mkdir -p SpeechToTextMac.app/Contents/Resources

# Copy binary
echo "📋 Copying binary..."
cp .build/release/SpeechToTextMac SpeechToTextMac.app/Contents/MacOS/

# Copy icon if it exists
if [ -f "AppIcon.icns" ]; then
    echo "🎨 Copying app icon..."
    cp AppIcon.icns SpeechToTextMac.app/Contents/Resources/
fi

# Create Info.plist
echo "📝 Creating Info.plist..."
cat > SpeechToTextMac.app/Contents/Info.plist <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>SpeechToTextMac</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.mgorunuch.SpeechToTextMac</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>SpeechToTextMac</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSMicrophoneUsageDescription</key>
    <string>This app needs access to your microphone to record speech for transcription.</string>
    <key>NSAppleEventsUsageDescription</key>
    <string>This app needs to control other applications to insert transcribed text.</string>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2024. All rights reserved.</string>
</dict>
</plist>
EOF

# Create PkgInfo
echo "APPL????" > SpeechToTextMac.app/Contents/PkgInfo

echo "✅ Build complete! SpeechToTextMac.app is ready."
echo ""
echo "To install:"
echo "  cp -r SpeechToTextMac.app /Applications/"
echo ""
echo "To run:"
echo "  open SpeechToTextMac.app"
