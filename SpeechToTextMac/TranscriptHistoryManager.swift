import Foundation

class TranscriptHistoryManager {
    static let shared = TranscriptHistoryManager()

    private let maxRecords = 50
    private let defaults = UserDefaults.standard
    private let fileQueue = DispatchQueue(label: "com.speech.history", qos: .userInitiated)

    private init() {
        ensureStorageDirectory()
    }

    var audioStorageURL: URL {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        let appFolder = appSupport.appendingPathComponent("com.yourname.SpeechToTextMac")
        let transcriptsFolder = appFolder.appendingPathComponent("transcripts")
        return transcriptsFolder
    }

    private func ensureStorageDirectory() {
        fileQueue.async { [weak self] in
            guard let self = self else { return }
            try? FileManager.default.createDirectory(
                at: self.audioStorageURL,
                withIntermediateDirectories: true
            )
        }
    }

    func save(text: String, provider: SpeechProvider, audioURL: URL) {
        var records = getAll()

        if records.count >= maxRecords {
            let oldest = records[0]
            delete(id: oldest.id)
            records.removeFirst()
        }

        let recordID = UUID()
        let audioFileName = "transcript_\(recordID.uuidString).wav"
        let record = TranscriptRecord(
            id: recordID,
            timestamp: Date(),
            text: text,
            provider: provider,
            audioFileName: audioFileName
        )

        fileQueue.async { [weak self] in
            guard let self = self else { return }
            let destinationURL = self.audioStorageURL.appendingPathComponent(audioFileName)

            do {
                try FileManager.default.copyItem(at: audioURL, to: destinationURL)
                print("✅ Audio saved to \(destinationURL.path)")
            } catch {
                print("❌ Failed to save audio: \(error)")
            }
        }

        records.append(record)
        saveRecordsToDefaults(records)
    }

    func getAll() -> [TranscriptRecord] {
        guard let data = defaults.data(forKey: "transcriptHistory"),
              let records = try? JSONDecoder().decode([TranscriptRecord].self, from: data) else {
            return []
        }
        return records.sorted { $0.timestamp > $1.timestamp }
    }

    func getRecent(limit: Int) -> [TranscriptRecord] {
        let all = getAll()
        return Array(all.prefix(limit))
    }

    func delete(id: UUID) {
        var records = getAll()
        guard let index = records.firstIndex(where: { $0.id == id }) else { return }
        let record = records[index]

        fileQueue.async {
            try? FileManager.default.removeItem(at: record.audioURL)
        }

        records.remove(at: index)
        saveRecordsToDefaults(records)
    }

    func retranscribe(record: TranscriptRecord, with provider: SpeechProvider, completion: @escaping (Result<String, Error>) -> Void) {
        fileQueue.async {
            guard FileManager.default.fileExists(atPath: record.audioURL.path) else {
                DispatchQueue.main.async {
                    completion(.failure(NSError(
                        domain: "TranscriptHistoryManager",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Audio file not found"]
                    )))
                }
                return
            }

            DispatchQueue.main.async {
                if provider.requiresAPIKey {
                    guard let apiKey = AppSettings.shared.getAPIKey(for: provider) else {
                        completion(.failure(NSError(
                            domain: "TranscriptHistoryManager",
                            code: -2,
                            userInfo: [NSLocalizedDescriptionKey: "\(provider.rawValue) API key not configured"]
                        )))
                        return
                    }

                    switch provider {
                    case .openai:
                        let client = OpenAIClient(apiKey: apiKey)
                        client.transcribe(audioFileURL: record.audioURL, completion: completion)
                    case .groq:
                        let client = GroqClient(apiKey: apiKey)
                        client.transcribe(audioFileURL: record.audioURL, completion: completion)
                    case .local:
                        break
                    }
                } else {
                    self.transcribeWithWhisper(audioURL: record.audioURL, completion: completion)
                }
            }
        }
    }

    private func saveRecordsToDefaults(_ records: [TranscriptRecord]) {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(records) {
            defaults.set(data, forKey: "transcriptHistory")
        }
    }

    private func transcribeWithWhisper(audioURL: URL, completion: @escaping (Result<String, Error>) -> Void) {
        let projectPath = "/Users/mgorunuch/projects/speech-to-text-mac"
        let whisperPath = "\(projectPath)/whisper/whisper-cli"
        let modelPath = "\(projectPath)/whisper/ggml-base.en.bin"

        let process = Process()
        process.executableURL = URL(fileURLWithPath: whisperPath)
        process.arguments = [
            "-m", modelPath,
            "-f", audioURL.path,
            "-nt",
            "-l", "en",
            "-np"
        ]

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try process.run()
                process.waitUntilExit()

                let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: outputData, encoding: .utf8) ?? ""

                let transcription = self.parseWhisperOutput(output)

                DispatchQueue.main.async {
                    if !transcription.isEmpty && transcription != "[BLANK_AUDIO]" {
                        completion(.success(transcription))
                    } else {
                        completion(.failure(NSError(
                            domain: "TranscriptHistoryManager",
                            code: -3,
                            userInfo: [NSLocalizedDescriptionKey: "No speech detected"]
                        )))
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }

    private func parseWhisperOutput(_ output: String) -> String {
        let lines = output.components(separatedBy: .newlines)
        var transcriptionLines: [String] = []

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)

            if trimmed.isEmpty {
                continue
            }

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

            transcriptionLines.append(trimmed)
        }

        return transcriptionLines.joined(separator: " ")
    }
}
