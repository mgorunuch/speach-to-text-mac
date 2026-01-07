import Foundation
import AVFoundation

class RecognizerManager {
    private let whisperRecognizer: WhisperRecognizer
    private var completionHandler: ((Result<String, Error>) -> Void)?
    private var isRecording = false

    init() {
        self.whisperRecognizer = WhisperRecognizer()
    }

    func requestPermission() {
        whisperRecognizer.requestPermission()
    }

    func startRecording(completion: @escaping (Result<String, Error>) -> Void) {
        self.completionHandler = completion
        isRecording = true

        let provider = AppSettings.shared.provider

        switch provider {
        case .local:
            startLocalRecording(completion: completion)

        case .openai:
            guard let apiKey = AppSettings.shared.getAPIKey(for: .openai) else {
                completion(.failure(NSError(
                    domain: "RecognizerManager",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "OpenAI API key not configured"]
                )))
                return
            }
            startAPIRecording(provider: .openai, apiKey: apiKey, completion: completion)

        case .groq:
            guard let apiKey = AppSettings.shared.getAPIKey(for: .groq) else {
                completion(.failure(NSError(
                    domain: "RecognizerManager",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Groq API key not configured"]
                )))
                return
            }
            startAPIRecording(provider: .groq, apiKey: apiKey, completion: completion)
        }
    }

    private func startLocalRecording(completion: @escaping (Result<String, Error>) -> Void) {
        whisperRecognizer.startRecording(completion: completion)
    }

    private func startAPIRecording(provider: SpeechProvider, apiKey: String, completion: @escaping (Result<String, Error>) -> Void) {
        // For API-based providers, we still need to record audio locally first
        whisperRecognizer.startRecording { [weak self] result in
            guard let self = self else { return }

            // Don't call the completion handler directly - we'll transcribe with the API instead
            // The WhisperRecognizer will save the audio file, and we'll use that
        }
    }

    func stopRecording() {
        guard isRecording else { return }
        isRecording = false

        let provider = AppSettings.shared.provider

        switch provider {
        case .local:
            whisperRecognizer.stopRecording()

        case .openai:
            stopAndTranscribeWithAPI(provider: .openai)

        case .groq:
            stopAndTranscribeWithAPI(provider: .groq)
        }
    }

    func cancelRecording() {
        guard isRecording else { return }
        isRecording = false

        whisperRecognizer.cancelRecording()
        completionHandler = nil
    }

    private func stopAndTranscribeWithAPI(provider: SpeechProvider) {
        // Stop the audio engine and get the recorded file
        let tempAudioPath = NSTemporaryDirectory() + "recording.wav"
        let audioURL = URL(fileURLWithPath: tempAudioPath)

        // Stop the whisper recognizer (which stops recording)
        // We need to access the audio file after stopping
        whisperRecognizer.stopRecordingWithoutTranscription()

        // Wait a bit for the file to be written
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }

            guard FileManager.default.fileExists(atPath: tempAudioPath) else {
                self.completionHandler?(.failure(NSError(
                    domain: "RecognizerManager",
                    code: -2,
                    userInfo: [NSLocalizedDescriptionKey: "Audio file not found"]
                )))
                return
            }

            guard let apiKey = AppSettings.shared.getAPIKey(for: provider) else {
                self.completionHandler?(.failure(NSError(
                    domain: "RecognizerManager",
                    code: -3,
                    userInfo: [NSLocalizedDescriptionKey: "API key not configured"]
                )))
                return
            }

            // Process prompt template with variable replacement
            let template = AppSettings.shared.promptTemplate
            let customPrompt = AppSettings.shared.whisperPrompt
            let outputLanguage = AppSettings.shared.outputLanguage
            let processedPrompt = PromptProcessor.process(template: template, customPrompt: customPrompt, language: outputLanguage)
            let promptToUse = processedPrompt.isEmpty ? nil : processedPrompt
            let languageCode = PromptProcessor.resolveLanguageCode(outputLanguage)

            switch provider {
            case .openai:
                let client = OpenAIClient(apiKey: apiKey)
                client.transcribe(audioFileURL: audioURL, prompt: promptToUse, language: languageCode) { [weak self] result in
                    DispatchQueue.main.async {
                        self?.completionHandler?(result)
                    }
                }

            case .groq:
                let client = GroqClient(apiKey: apiKey)
                client.transcribe(audioFileURL: audioURL, prompt: promptToUse, language: languageCode) { [weak self] result in
                    DispatchQueue.main.async {
                        self?.completionHandler?(result)
                    }
                }

            case .local:
                break // Already handled
            }
        }
    }
}
