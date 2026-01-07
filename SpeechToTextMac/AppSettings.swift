import Foundation

enum OutputLanguage: String, CaseIterable, Codable {
    case auto = "Auto"
    case english = "English"
    case russian = "Russian"
    case spanish = "Spanish"
    case french = "French"
    case german = "German"
    case chinese = "Chinese"
    case japanese = "Japanese"
    case korean = "Korean"
    case portuguese = "Portuguese"
    case italian = "Italian"
    case ukrainian = "Ukrainian"

    var displayName: String { rawValue }

    var promptDescription: String {
        switch self {
        case .auto:
            return "the same language as the input"
        default:
            return rawValue
        }
    }

    var languageCode: String? {
        switch self {
        case .auto: return nil
        case .english: return "en"
        case .russian: return "ru"
        case .spanish: return "es"
        case .french: return "fr"
        case .german: return "de"
        case .chinese: return "zh"
        case .japanese: return "ja"
        case .korean: return "ko"
        case .portuguese: return "pt"
        case .italian: return "it"
        case .ukrainian: return "uk"
        }
    }
}

enum SpeechProvider: String, CaseIterable, Codable {
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
        static let whisperPrompt = "whisperPrompt"
        static let promptTemplate = "promptTemplate"
        static let hotkey = "hotkey"
        static let outputLanguage = "outputLanguage"
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

    var whisperPrompt: String {
        get {
            defaults.string(forKey: Keys.whisperPrompt) ?? ""
        }
        set {
            defaults.set(newValue, forKey: Keys.whisperPrompt)
        }
    }

    var promptTemplate: PromptTemplate {
        get {
            if let rawValue = defaults.string(forKey: Keys.promptTemplate),
               let template = PromptTemplate(rawValue: rawValue) {
                return template
            }
            return .none
        }
        set {
            defaults.set(newValue.rawValue, forKey: Keys.promptTemplate)
        }
    }

    var hotkey: HotkeyConfiguration {
        get {
            if let data = defaults.data(forKey: Keys.hotkey),
               let config = try? JSONDecoder().decode(HotkeyConfiguration.self, from: data) {
                return config
            }
            return .defaultHotkey
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                defaults.set(data, forKey: Keys.hotkey)
            }
        }
    }

    var outputLanguage: OutputLanguage {
        get {
            if let rawValue = defaults.string(forKey: Keys.outputLanguage),
               let language = OutputLanguage(rawValue: rawValue) {
                return language
            }
            return .auto
        }
        set {
            defaults.set(newValue.rawValue, forKey: Keys.outputLanguage)
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
