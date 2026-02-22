import SwiftUI

struct AboutScreen: View {
    @Environment(\.locale) private var locale
    @State private var tab = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Swigrid")
                .font(.system(size: 36, weight: .bold, design: .serif))

            Text(L10n.text("Train your focus and visual scanning skills with a fluid native iOS experience."))
                .foregroundStyle(.secondary)

            Picker(L10n.text("Content"), selection: $tab) {
                Text(L10n.text("How to Play")).tag(0)
                Text(L10n.text("What's New")).tag(1)
            }
            .pickerStyle(.segmented)

            ScrollView {
                _SizingMarkdownView(
                    markdown: tab == 0 ? helpMarkdown : changelogMarkdown,
                    width: 0   // will be resolved by sizeThatFits
                )
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Spacer()
        }
        .padding(20)
        .navigationTitle(L10n.text("About"))
        .edgeOnlySwipeBack()
    }

    private var helpMarkdown: String {
        loadLocalizedMarkdown(baseName: "help") ?? L10n.text("Help content is unavailable.")
    }

    private var changelogMarkdown: String {
        loadLocalizedMarkdown(baseName: "changelog") ?? L10n.text("No changelog entries.")
    }

    private func loadLocalizedMarkdown(baseName: String) -> String? {
        for filename in preferredMarkdownFilenames(baseName: baseName) {
            if let markdown = loadMarkdown(named: filename) {
                return markdown
            }
        }
        return nil
    }

    private func preferredMarkdownFilenames(baseName: String) -> [String] {
        if prefersChineseMarkdown {
            return ["\(baseName)_zh.md", "\(baseName).md"]
        }
        return ["\(baseName).md"]
    }

    private var prefersChineseMarkdown: Bool {
        let modulePreferredLocalization = Bundle.module.preferredLocalizations.first?.lowercased() ?? ""
        if modulePreferredLocalization.hasPrefix("zh") {
            return true
        }

        if locale.identifier.lowercased().hasPrefix("zh") {
            return true
        }

        return Locale.preferredLanguages.contains { language in
            language.lowercased().hasPrefix("zh")
        }
    }

    private func loadMarkdown(named filename: String) -> String? {
        guard let url = Bundle.module.url(forResource: filename, withExtension: nil, subdirectory: "md") else {
            return nil
        }

        return try? String(contentsOf: url, encoding: .utf8)
    }
}
