.PHONY: build run clean install help

help:
	@echo "🎙️  SpeechToTextMac - Voice to Text for macOS"
	@echo ""
	@echo "Available commands:"
	@echo "  make build    - Build the app in release mode"
	@echo "  make run      - Build and run the app"
	@echo "  make clean    - Clean build artifacts"
	@echo "  make install  - Build and copy to Applications folder"
	@echo "  make help     - Show this help message"

build:
	@echo "📦 Building SpeechToTextMac..."
	@swift build -c release
	@echo "✅ Build complete!"

run: build
	@echo "🚀 Running SpeechToTextMac..."
	@.build/release/SpeechToTextMac

clean:
	@echo "🧹 Cleaning build artifacts..."
	@swift package clean
	@rm -rf .build
	@echo "✅ Clean complete!"

install: build
	@echo "📲 Installing to Applications folder..."
	@mkdir -p ~/Applications
	@cp -f .build/release/SpeechToTextMac ~/Applications/
	@echo "✅ Installed to ~/Applications/SpeechToTextMac"
	@echo ""
	@echo "⚠️  Don't forget to grant permissions:"
	@echo "   System Preferences → Privacy & Security → Accessibility"
