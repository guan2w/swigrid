import Foundation

enum L10n {
    private static let englishTable = loadTable(localization: "en")
    private static let chineseTable = loadTable(localization: "zh-Hans")

    static func text(_ key: String) -> String {
        let primary = prefersChinese ? chineseTable : englishTable
        let fallback = prefersChinese ? englishTable : chineseTable
        return primary[key] ?? fallback[key] ?? key
    }

    static func format(_ key: String, _ args: CVarArg...) -> String {
        String(format: text(key), locale: Locale.current, arguments: args)
    }

    private static var prefersChinese: Bool {
        let preferredLanguages = Locale.preferredLanguages.map { $0.lowercased() }
        if preferredLanguages.contains(where: { $0.hasPrefix("zh") }) {
            return true
        }

        let appleLanguages = UserDefaults.standard.stringArray(forKey: "AppleLanguages") ?? []
        if appleLanguages.map({ $0.lowercased() }).contains(where: { $0.hasPrefix("zh") }) {
            return true
        }

        return Locale.autoupdatingCurrent.identifier.lowercased().hasPrefix("zh")
    }

    private static func loadTable(localization: String) -> [String: String] {
        guard
            let lprojURL = Bundle.module.url(forResource: localization, withExtension: "lproj"),
            let lprojBundle = Bundle(url: lprojURL),
            let stringsURL = lprojBundle.url(forResource: "Localizable", withExtension: "strings"),
            let dict = NSDictionary(contentsOf: stringsURL) as? [String: String]
        else {
            return [:]
        }

        return dict
    }
}
