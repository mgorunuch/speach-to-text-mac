#!/bin/bash
# Build script for SpeechToTextMac

set -e

echo "🎙️  Building SpeechToTextMac..."

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Xcode is not installed. Please install Xcode from the App Store."
    exit 1
fi

# Check if Swift is available
if ! command -v swift &> /dev/null; then
    echo "❌ Swift is not installed."
    exit 1
fi

echo "✅ Xcode and Swift detected"

# Build with Swift Package Manager
echo "📦 Building with Swift Package Manager..."
swift build -c release

# Check if build was successful
if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    echo ""
    echo "🚀 To run the app:"
    echo "   .build/release/SpeechToTextMac"
    echo ""
    echo "📝 Remember to grant permissions:"
    echo "   1. Microphone access (auto-prompted)"
    echo "   2. Speech Recognition (auto-prompted)"
    echo "   3. Accessibility (System Preferences → Privacy & Security)"
else
    echo "❌ Build failed"
    exit 1
fi
