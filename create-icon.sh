#!/bin/bash

# Create icon from PNG file

set -e

SOURCE_ICON="$HOME/Downloads/stt-favicon.png"
ICONSET_DIR="AppIcon.iconset"

echo "🎨 Creating app icon from $SOURCE_ICON..."

# Check if source exists
if [ ! -f "$SOURCE_ICON" ]; then
    echo "❌ Error: Icon file not found at $SOURCE_ICON"
    exit 1
fi

# Create iconset directory
mkdir -p "$ICONSET_DIR"

# Generate different sizes for macOS app icon
# macOS requires multiple sizes: 16, 32, 64, 128, 256, 512, 1024
echo "📐 Generating icon sizes..."

sips -z 16 16     "$SOURCE_ICON" --out "$ICONSET_DIR/icon_16x16.png" > /dev/null
sips -z 32 32     "$SOURCE_ICON" --out "$ICONSET_DIR/icon_16x16@2x.png" > /dev/null
sips -z 32 32     "$SOURCE_ICON" --out "$ICONSET_DIR/icon_32x32.png" > /dev/null
sips -z 64 64     "$SOURCE_ICON" --out "$ICONSET_DIR/icon_32x32@2x.png" > /dev/null
sips -z 128 128   "$SOURCE_ICON" --out "$ICONSET_DIR/icon_128x128.png" > /dev/null
sips -z 256 256   "$SOURCE_ICON" --out "$ICONSET_DIR/icon_128x128@2x.png" > /dev/null
sips -z 256 256   "$SOURCE_ICON" --out "$ICONSET_DIR/icon_256x256.png" > /dev/null
sips -z 512 512   "$SOURCE_ICON" --out "$ICONSET_DIR/icon_256x256@2x.png" > /dev/null
sips -z 512 512   "$SOURCE_ICON" --out "$ICONSET_DIR/icon_512x512.png" > /dev/null
sips -z 1024 1024 "$SOURCE_ICON" --out "$ICONSET_DIR/icon_512x512@2x.png" > /dev/null

# Convert to icns
echo "🔄 Converting to .icns format..."
iconutil -c icns "$ICONSET_DIR" -o AppIcon.icns

# Clean up iconset directory
rm -rf "$ICONSET_DIR"

echo "✅ Icon created: AppIcon.icns"
