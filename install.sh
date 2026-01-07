#!/bin/bash

# Install script for SpeechToTextMac

set -e

echo "🚀 Installing SpeechToTextMac..."

# Build the app first
./build-app.sh

# Install to Applications
echo "📦 Installing to /Applications..."
if [ -d "/Applications/SpeechToTextMac.app" ]; then
    echo "⚠️  Removing old version..."
    rm -rf /Applications/SpeechToTextMac.app
fi

cp -r SpeechToTextMac.app /Applications/

echo "✅ Installation complete!"
echo ""
echo "SpeechToTextMac has been installed to /Applications"
echo ""
echo "To launch:"
echo "  open /Applications/SpeechToTextMac.app"
echo ""
echo "Or find it in your Applications folder!"
