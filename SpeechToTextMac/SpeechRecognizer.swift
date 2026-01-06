import Foundation
import Speech
import AVFoundation

class SpeechRecognizer {
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    private var completionHandler: ((Result<String, Error>) -> Void)?
    private var latestTranscription: String = ""

    init() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    }

    func requestPermission() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    print("Speech recognition authorized")
                case .denied, .restricted, .notDetermined:
                    print("Speech recognition not authorized")
                @unknown default:
                    print("Unknown authorization status")
                }
            }
        }
    }

    func startRecording(completion: @escaping (Result<String, Error>) -> Void) {
        self.completionHandler = completion

        // Cancel previous task if exists
        recognitionTask?.cancel()
        recognitionTask = nil

        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()

        guard let recognitionRequest = recognitionRequest else {
            completion(.failure(NSError(domain: "SpeechRecognizer", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to create recognition request"])))
            return
        }

        recognitionRequest.shouldReportPartialResults = true

        // Configure audio engine
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }

        audioEngine.prepare()

        do {
            try audioEngine.start()
        } catch {
            completion(.failure(error))
            return
        }

        // Start recognition task
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }

            if let error = error {
                // Ignore "no speech detected" errors during recording
                let nsError = error as NSError
                if nsError.domain == "kAFAssistantErrorDomain" && nsError.code == 1110 {
                    // Continue recording, don't stop
                    print("Waiting for speech...")
                    return
                }

                print("Speech recognition error: \(error.localizedDescription)")
                // Don't auto-stop on errors, let user manually stop
                return
            }

            if let result = result {
                let transcription = result.bestTranscription.formattedString
                print("Transcription: \(transcription)")

                // Don't auto-stop, let user press F13 again
                // Store the latest transcription
                self.latestTranscription = transcription
            }
        }
    }

    func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()

        // Wait a bit for final results
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }

            if !self.latestTranscription.isEmpty {
                self.completionHandler?(.success(self.latestTranscription))
            } else {
                self.completionHandler?(.failure(NSError(domain: "SpeechRecognizer", code: -1, userInfo: [NSLocalizedDescriptionKey: "No speech detected"])))
            }

            self.recognitionTask?.cancel()
            self.recognitionRequest = nil
            self.recognitionTask = nil
            self.latestTranscription = ""
        }
    }
}
