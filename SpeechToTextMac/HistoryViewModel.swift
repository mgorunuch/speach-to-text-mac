import Foundation
import AppKit

@MainActor
class HistoryViewModel: ObservableObject {
    @Published var transcripts: [TranscriptRecord] = []
    @Published var searchText = ""
    @Published var isRetranscribing = false
    @Published var retranscriptionResult: String?
    @Published var retranscriptionError: String?

    var filteredTranscripts: [TranscriptRecord] {
        if searchText.isEmpty {
            return transcripts
        }
        return transcripts.filter {
            $0.text.localizedCaseInsensitiveContains(searchText)
        }
    }

    func loadTranscripts() {
        transcripts = TranscriptHistoryManager.shared.getAll()
    }

    func copy(_ record: TranscriptRecord) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(record.text, forType: .string)
        print("📋 Copied transcript to clipboard")
    }

    func delete(_ record: TranscriptRecord) {
        TranscriptHistoryManager.shared.delete(id: record.id)
        loadTranscripts()
    }

    func retranscribe(_ record: TranscriptRecord, with provider: SpeechProvider) {
        isRetranscribing = true
        retranscriptionResult = nil
        retranscriptionError = nil

        TranscriptHistoryManager.shared.retranscribe(record: record, with: provider) { [weak self] result in
            guard let self = self else { return }

            Task { @MainActor in
                self.isRetranscribing = false

                switch result {
                case .success(let newText):
                    self.retranscriptionResult = newText
                    print("✅ Re-transcription successful: \(newText)")
                case .failure(let error):
                    self.retranscriptionError = error.localizedDescription
                    print("❌ Re-transcription failed: \(error.localizedDescription)")
                }
            }
        }
    }

    func clearRetranscriptionResult() {
        retranscriptionResult = nil
        retranscriptionError = nil
    }
}
