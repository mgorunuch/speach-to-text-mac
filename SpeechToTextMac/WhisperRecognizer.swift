import Foundation
import AVFoundation
import CoreAudio

class WhisperRecognizer {
    private let audioEngine = AVAudioEngine()
    private var audioFile: AVAudioFile?
    private var isRecording = false
    private var completionHandler: ((Result<String, Error>) -> Void)?

    private let whisperPath: String
    private let modelPath: String
    private let tempAudioPath: String

    // Load preferred device from UserDefaults
    private var preferredDeviceID: AudioDeviceID? {
        if let savedID = UserDefaults.standard.object(forKey: "preferredDeviceID") as? UInt32 {
            return savedID
        }
        return nil
    }

    init() {
        // Get paths relative to the app bundle or project
        let projectPath = "/Users/mgorunuch/projects/speech-to-text-mac"
        self.whisperPath = "\(projectPath)/whisper/whisper-cli"
        self.modelPath = "\(projectPath)/whisper/ggml-base.en.bin"
        self.tempAudioPath = NSTemporaryDirectory() + "recording.wav"
    }

    func requestPermission() {
        // Request microphone permission (same as before)
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            DispatchQueue.main.async {
                if granted {
                    print("✅ Microphone access granted")
                } else {
                    print("❌ Microphone access denied")
                }
            }
        }
    }

    func startRecording(completion: @escaping (Result<String, Error>) -> Void) {
        self.completionHandler = completion

        // List available audio devices
        listAllAudioDevices()

        // IMPORTANT: Set preferred device BEFORE accessing audioEngine
        if let deviceID = preferredDeviceID {
            // Stop and reset audio engine first
            if audioEngine.isRunning {
                audioEngine.stop()
            }
            audioEngine.reset()

            // Set the device
            setInputDevice(deviceID)

            // Wait for device to be ready
            Thread.sleep(forTimeInterval: 0.2)

            // Verify the device was set correctly
            let actualDevice = getCurrentInputDeviceID()
            if actualDevice != deviceID {
                print("⚠️  Warning: Requested device \(deviceID), but system is using \(actualDevice)")
            }
        }

        // Remove old temp file if exists
        try? FileManager.default.removeItem(atPath: tempAudioPath)

        // Use the input node's native format (simpler, no conversion needed)
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        // Show current input device
        let inputDevice = audioEngine.inputNode.auAudioUnit.deviceID
        print("🎤 Actually using device ID: \(inputDevice)")

        // Verify we're using the correct device
        if let preferredID = preferredDeviceID, inputDevice != preferredID {
            print("⚠️  AudioEngine using different device! Requested: \(preferredID), Got: \(inputDevice)")
        } else if let preferredID = preferredDeviceID {
            print("✅ Confirmed using preferred device \(preferredID)")
        }

        // Create audio file for recording
        let audioFileURL = URL(fileURLWithPath: tempAudioPath)
        do {
            audioFile = try AVAudioFile(
                forWriting: audioFileURL,
                settings: recordingFormat.settings
            )
        } catch {
            print("Error creating audio file: \(error.localizedDescription)")
            completion(.failure(error))
            return
        }

        // Install tap to capture audio with buffer monitoring
        var bufferCount = 0
        inputNode.installTap(onBus: 0, bufferSize: 4096, format: recordingFormat) { [weak self] buffer, _ in
            guard let self = self, let audioFile = self.audioFile else { return }

            bufferCount += 1

            // Check audio level
            if bufferCount % 50 == 0 {  // Every 50 buffers
                let level = self.getAudioLevel(buffer: buffer)
                print("📊 Audio level: \(String(format: "%.2f", level)) dB")
            }

            do {
                try audioFile.write(from: buffer)
            } catch {
                print("Error writing audio: \(error.localizedDescription)")
            }
        }

        // Start audio engine
        audioEngine.prepare()
        do {
            try audioEngine.start()
            isRecording = true
            print("🎙️ Recording audio to \(tempAudioPath)")
            print("Format: \(recordingFormat.sampleRate)Hz, \(recordingFormat.channelCount) channels")
        } catch {
            completion(.failure(error))
        }
    }

    private func listAllAudioDevices() {
        print("🎧 ========== AVAILABLE AUDIO INPUT DEVICES ==========")

        #if os(macOS)
        // Get all devices
        var propertySize: UInt32 = 0
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &propertyAddress, 0, nil, &propertySize)

        let deviceCount = Int(propertySize) / MemoryLayout<AudioDeviceID>.size
        var deviceIDs = [AudioDeviceID](repeating: 0, count: deviceCount)

        AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &propertyAddress, 0, nil, &propertySize, &deviceIDs)

        // Get default device
        var defaultDeviceID = AudioDeviceID(0)
        var defaultSize: UInt32 = UInt32(MemoryLayout<AudioDeviceID>.size)
        var defaultInputAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &defaultInputAddress, 0, nil, &defaultSize, &defaultDeviceID)

        for deviceID in deviceIDs {
            // Check if it has input channels
            var streamAddress = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyStreamConfiguration,
                mScope: kAudioDevicePropertyScopeInput,
                mElement: 0
            )

            var streamSize: UInt32 = 0
            guard AudioObjectGetPropertyDataSize(deviceID, &streamAddress, 0, nil, &streamSize) == noErr else { continue }

            var bufferList = AudioBufferList()
            guard AudioObjectGetPropertyData(deviceID, &streamAddress, 0, nil, &streamSize, &bufferList) == noErr else { continue }

            if bufferList.mNumberBuffers > 0 {
                // Get device name
                var deviceName: CFString = "" as CFString
                var nameSize = UInt32(MemoryLayout<CFString>.size)
                var nameAddress = AudioObjectPropertyAddress(
                    mSelector: kAudioDevicePropertyDeviceNameCFString,
                    mScope: kAudioObjectPropertyScopeGlobal,
                    mElement: kAudioObjectPropertyElementMain
                )

                let isDefault = deviceID == defaultDeviceID
                let marker = isDefault ? " ⭐️ (DEFAULT)" : ""

                if AudioObjectGetPropertyData(deviceID, &nameAddress, 0, nil, &nameSize, &deviceName) == noErr {
                    print("  📍 ID: \(deviceID) - \(deviceName)\(marker)")
                } else {
                    print("  📍 ID: \(deviceID) - Unknown Device\(marker)")
                }
            }
        }

        print("====================================================")
        print("💡 To use a specific device, set preferredDeviceID in WhisperRecognizer.swift")
        print("   Example: private var preferredDeviceID: AudioDeviceID? = 73")
        print("====================================================")
        #endif
    }

    private func getCurrentInputDeviceID() -> AudioDeviceID {
        #if os(macOS)
        var deviceID = AudioDeviceID(0)
        var propertySize: UInt32 = UInt32(MemoryLayout<AudioDeviceID>.size)
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &propertySize,
            &deviceID
        )

        return deviceID
        #else
        return 0
        #endif
    }

    private func setInputDevice(_ deviceID: AudioDeviceID) {
        #if os(macOS)
        print("🔧 Setting system input device to ID: \(deviceID)")

        var mutableDeviceID = deviceID
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        let status = AudioObjectSetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            UInt32(MemoryLayout<AudioDeviceID>.size),
            &mutableDeviceID
        )

        if status == noErr {
            print("✅ System input device set to \(deviceID)")

            // Verify it was actually set
            let currentDevice = getCurrentInputDeviceID()
            if currentDevice == deviceID {
                print("✅ Verified: System now using device \(currentDevice)")
            } else {
                print("⚠️  System defaulted to device \(currentDevice) instead")
            }
        } else {
            print("❌ Failed to set input device. Error code: \(status)")
        }
        #endif
    }

    private func getAudioLevel(buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData else { return -160.0 }
        let channelDataValue = channelData.pointee
        let channelDataValueArray = stride(from: 0, to: Int(buffer.frameLength), by: buffer.stride).map { channelDataValue[$0] }
        let rms = sqrt(channelDataValueArray.map { $0 * $0 }.reduce(0, +) / Float(buffer.frameLength))
        let avgPower = 20 * log10(rms)
        return avgPower
    }

    func stopRecording() {
        guard isRecording else { return }

        print("⏹️ Stopping recording")

        // Stop audio engine
        if audioEngine.isRunning {
            audioEngine.stop()
        }

        audioEngine.inputNode.removeTap(onBus: 0)
        isRecording = false

        // Close audio file
        audioFile = nil

        // Transcribe with Whisper
        transcribeWithWhisper()
    }

    func stopRecordingWithoutTranscription() {
        guard isRecording else { return }

        print("⏹️ Stopping recording (no transcription)")

        // Stop audio engine
        if audioEngine.isRunning {
            audioEngine.stop()
        }

        audioEngine.inputNode.removeTap(onBus: 0)
        isRecording = false

        // Close audio file
        audioFile = nil
    }

    func cancelRecording() {
        guard isRecording else { return }

        print("🚫 Recording cancelled")

        // Stop audio engine
        if audioEngine.isRunning {
            audioEngine.stop()
        }

        audioEngine.inputNode.removeTap(onBus: 0)
        isRecording = false

        // Close and cleanup audio file
        audioFile = nil

        // Clear completion handler to prevent any callback
        completionHandler = nil
    }

    private func transcribeWithWhisper(language: String? = nil) {
        print("🔄 Transcribing with Whisper...")

        let languageCode = language ?? PromptProcessor.resolveLanguageCode(AppSettings.shared.outputLanguage) ?? "en"
        print("🌐 Using language: \(languageCode)")

        let process = Process()
        process.executableURL = URL(fileURLWithPath: whisperPath)
        process.arguments = [
            "-m", modelPath,
            "-f", tempAudioPath,
            "-nt",  // No timestamps
            "-l", languageCode,
            "-np"   // No print progress
        ]

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe  // Separate stderr to avoid debug output

        do {
            try process.run()
            process.waitUntilExit()

            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: outputData, encoding: .utf8) ?? ""

            // Debug: print stderr (optional)
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let errorOutput = String(data: errorData, encoding: .utf8) ?? ""
            if !errorOutput.isEmpty {
                print("Whisper debug:\n\(errorOutput)")
            }

            // Parse transcription from output
            let transcription = parseWhisperOutput(output)

            if !transcription.isEmpty && transcription != "[BLANK_AUDIO]" {
                print("✅ Transcription: \(transcription)")
                completionHandler?(.success(transcription))
            } else {
                print("❌ No speech detected or blank audio")
                completionHandler?(.failure(NSError(
                    domain: "WhisperRecognizer",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "No speech detected"]
                )))
            }
        } catch {
            print("❌ Whisper error: \(error.localizedDescription)")
            completionHandler?(.failure(error))
        }
    }

    private func parseWhisperOutput(_ output: String) -> String {
        // Whisper output format (with -nt flag): just the transcribed text
        let lines = output.components(separatedBy: .newlines)
        var transcriptionLines: [String] = []

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)

            // Skip empty lines
            if trimmed.isEmpty {
                continue
            }

            // Skip lines that are clearly debug/system output
            if trimmed.hasPrefix("[") ||
               trimmed.contains("whisper_") ||
               trimmed.contains("ggml_") ||
               trimmed.contains("system_info") ||
               trimmed.contains("main:") ||
               trimmed.contains("GPU") ||
               trimmed.contains("Metal") ||
               trimmed.contains("MB") {
                continue
            }

            // This should be the transcription
            transcriptionLines.append(trimmed)
        }

        let result = transcriptionLines.joined(separator: " ")
        print("Parsed transcription: '\(result)'")
        return result
    }

}
