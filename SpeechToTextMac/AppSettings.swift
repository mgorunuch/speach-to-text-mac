import Foundation

enum SpeechProvider: String, CaseIterable {
    case local = "Local Whisper"
    case openai = "OpenAI"
    case groq = "Groq"

    var requiresAPIKey: Bool {
        switch self {
        case .local:
            return false
        case .openai, .groq:
            return true
        }
    }
}

class AppSettings {
    static let shared = AppSettings()

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let provider = "speechProvider"
        static let openAIKey = "openAIKey"
        static let groqKey = "groqKey"
    }

    var provider: SpeechProvider {
        get {
            if let rawValue = defaults.string(forKey: Keys.provider),
               let provider = SpeechProvider(rawValue: rawValue) {
                return provider
            }
            return .local
        }
        set {
            defaults.set(newValue.rawValue, forKey: Keys.provider)
        }
    }

    var openAIKey: String {
        get {
            defaults.string(forKey: Keys.openAIKey) ?? ""
        }
        set {
            defaults.set(newValue, forKey: Keys.openAIKey)
        }
    }

    var groqKey: String {
        get {
            defaults.string(forKey: Keys.groqKey) ?? ""
        }
        set {
            defaults.set(newValue, forKey: Keys.groqKey)
        }
    }

    func getAPIKey(for provider: SpeechProvider) -> String? {
        switch provider {
        case .local:
            return nil
        case .openai:
            return openAIKey.isEmpty ? nil : openAIKey
        case .groq:
            return groqKey.isEmpty ? nil : groqKey
        }
    }

    func isProviderConfigured(_ provider: SpeechProvider) -> Bool {
        if !provider.requiresAPIKey {
            return true
        }
        return getAPIKey(for: provider) != nil
    }
}
