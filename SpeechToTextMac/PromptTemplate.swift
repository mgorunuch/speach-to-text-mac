import Foundation
import AppKit
import Carbon

enum PromptTemplate: String, CaseIterable, Codable {
    case none = "None"
    case professional = "Professional"
    case casual = "Casual"
    case structured = "Structured"
    case technical = "Technical"
    case creative = "Creative"
    case custom = "Custom"

    var displayName: String {
        rawValue
    }

    var promptText: String {
        switch self {
        case .none:
            return "Output in %Language."
        case .professional:
            return "Professional business communication for %ActiveApp. Use proper grammar, formal tone, and clear structure. Output in %Language."
        case .casual:
            return "Casual, conversational tone for %ActiveApp. Natural speech with common contractions and informal language. Output in %Language."
        case .structured:
            return "Well-structured content for %ActiveApp. Organize thoughts with clear points, proper punctuation, and logical flow. Output in %Language."
        case .technical:
            return "Technical discussion for %ActiveApp. Accurate terminology, precise language, and technical accuracy. Common terms: API, database, server, function, variable, configuration. Output in %Language."
        case .creative:
            return "Creative and expressive writing for %ActiveApp. Vivid language, descriptive phrases, and engaging narrative. Output in %Language."
        case .custom:
            return "" // User provides their own
        }
    }

    var description: String {
        switch self {
        case .none:
            return "No prompt guidance"
        case .professional:
            return "Formal business tone"
        case .casual:
            return "Relaxed, conversational"
        case .structured:
            return "Organized with clear points"
        case .technical:
            return "Technical terms & precision"
        case .creative:
            return "Expressive & descriptive"
        case .custom:
            return "Write your own prompt"
        }
    }
}

class PromptProcessor {
    static func process(template: PromptTemplate, customPrompt: String = "", language: OutputLanguage = AppSettings.shared.outputLanguage) -> String {
        let basePrompt: String

        if template == .custom {
            basePrompt = customPrompt
        } else {
            basePrompt = template.promptText
        }

        // Replace variables
        var processed = basePrompt
        processed = processed.replacingOccurrences(of: "%ActiveApp", with: getActiveApplicationName())
        processed = processed.replacingOccurrences(of: "%Language", with: resolveLanguage(language))

        return processed
    }

    private static func resolveLanguage(_ language: OutputLanguage) -> String {
        guard language == .auto else {
            return language.promptDescription
        }

        return getKeyboardLanguage() ?? "the same language as the input"
    }

    static func resolveLanguageCode(_ language: OutputLanguage) -> String? {
        guard language == .auto else {
            return language.languageCode
        }

        return getKeyboardLanguageCode()
    }

    private static func getKeyboardLanguageCode() -> String? {
        guard let inputSource = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue() else {
            return nil
        }

        guard let languagesPtr = TISGetInputSourceProperty(inputSource, kTISPropertyInputSourceLanguages) else {
            return nil
        }

        let languages = Unmanaged<CFArray>.fromOpaque(languagesPtr).takeUnretainedValue() as? [String]
        guard let primaryLanguage = languages?.first else {
            return nil
        }

        return primaryLanguage.components(separatedBy: "-").first
    }

    private static func getKeyboardLanguage() -> String? {
        guard let inputSource = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue() else {
            return nil
        }

        guard let languagesPtr = TISGetInputSourceProperty(inputSource, kTISPropertyInputSourceLanguages) else {
            return nil
        }

        let languages = Unmanaged<CFArray>.fromOpaque(languagesPtr).takeUnretainedValue() as? [String]
        guard let primaryLanguage = languages?.first else {
            return nil
        }

        return mapLanguageCodeToName(primaryLanguage)
    }

    private static func mapLanguageCodeToName(_ code: String) -> String {
        let languageMap: [String: String] = [
            "en": "English",
            "ru": "Russian",
            "es": "Spanish",
            "fr": "French",
            "de": "German",
            "zh": "Chinese",
            "ja": "Japanese",
            "ko": "Korean",
            "pt": "Portuguese",
            "it": "Italian",
            "uk": "Ukrainian",
            "pl": "Polish",
            "nl": "Dutch",
            "ar": "Arabic",
            "he": "Hebrew",
            "tr": "Turkish",
            "vi": "Vietnamese",
            "th": "Thai",
            "cs": "Czech",
            "sv": "Swedish",
            "da": "Danish",
            "fi": "Finnish",
            "no": "Norwegian",
            "hu": "Hungarian",
            "el": "Greek",
            "ro": "Romanian",
            "bg": "Bulgarian",
            "hr": "Croatian",
            "sk": "Slovak",
            "sl": "Slovenian"
        ]

        let baseCode = code.components(separatedBy: "-").first ?? code
        return languageMap[baseCode] ?? code.uppercased()
    }

    private static func getActiveApplicationName() -> String {
        guard let activeApp = NSWorkspace.shared.frontmostApplication else {
            return "Unknown"
        }

        return activeApp.localizedName ?? "Unknown"
    }
}
