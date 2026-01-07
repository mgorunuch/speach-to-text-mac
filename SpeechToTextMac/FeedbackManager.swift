import Foundation
import AppKit
import AVFoundation

class FeedbackManager {
    static let shared = FeedbackManager()

    private var audioPlayer: AVAudioPlayer?

    enum FeedbackType {
        case recordingStarted
        case recordingStopped
        case transcribing
        case completed
        case error
        case cancelled
    }

    func playFeedback(_ type: FeedbackType) {
        let systemSound: NSSound.Name

        switch type {
        case .recordingStarted:
            systemSound = .init("Tink")
        case .recordingStopped:
            systemSound = .init("Pop")
        case .transcribing:
            systemSound = .init("Morse")
        case .completed:
            systemSound = .init("Glass")
        case .error:
            systemSound = .init("Basso")
        case .cancelled:
            systemSound = .init("Funk")
        }

        if let sound = NSSound(named: systemSound) {
            sound.play()
        }
    }

    func provideHapticFeedback() {
        NSHapticFeedbackManager.defaultPerformer.perform(
            .alignment,
            performanceTime: .default
        )
    }
}
