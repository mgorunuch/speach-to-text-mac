import Foundation

struct TranscriptRecord: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let text: String
    let provider: SpeechProvider
    let audioFileName: String

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }

    var audioURL: URL {
        return TranscriptHistoryManager.shared.audioStorageURL
            .appendingPathComponent(audioFileName)
    }
}
