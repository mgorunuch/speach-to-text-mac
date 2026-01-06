# Whisper Integration

This directory contains the OpenAI Whisper binaries and models for speech-to-text transcription.

## Files

- `whisper-cli` - The whisper.cpp binary (native C++ implementation)
- `ggml-base.en.bin` - Whisper base English model (~141MB)

## How it works

1. **Recording**: Audio is captured via `AVAudioEngine` and saved to a temporary WAV file (16kHz, mono, PCM)
2. **Transcription**: The `whisper-cli` binary processes the WAV file
3. **Output**: Transcribed text is parsed and inserted into the active application

## Models

Different models offer different speed/accuracy tradeoffs:

| Model | Size | Speed | Accuracy |
|-------|------|-------|----------|
| tiny.en | 75MB | Fastest | Good |
| base.en | 141MB | Fast | Better ✅ (Current) |
| small.en | 466MB | Medium | Great |
| medium.en | 1.5GB | Slow | Excellent |

## Rebuild Instructions

If you need to rebuild or update whisper.cpp:

```bash
# Clone and build
cd /tmp
git clone https://github.com/ggerganov/whisper.cpp.git
cd whisper.cpp
make

# Download model (replace base.en with your choice)
bash ./models/download-ggml-model.sh base.en

# Copy to project
cp build/bin/whisper-cli /path/to/project/whisper/
cp models/ggml-base.en.bin /path/to/project/whisper/
```

## Performance

- **base.en model**: ~1-2 seconds for 5-second audio on M1/M2 Mac
- Uses Metal acceleration when available
- Runs entirely offline (no internet needed)

## Privacy

All transcription happens **locally on your Mac**. No audio or text data leaves your device.
