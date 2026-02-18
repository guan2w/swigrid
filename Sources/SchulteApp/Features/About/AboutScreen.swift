import SwiftUI

struct AboutScreen: View {
    @State private var tab = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Schulte Grid")
                .font(.system(size: 36, weight: .bold, design: .serif))

            Text("A focus and visual scanning game, rebuilt with native iOS interactions.")
                .foregroundStyle(.secondary)

            Picker("Content", selection: $tab) {
                Text("Help").tag(0)
                Text("Changelog").tag(1)
            }
            .pickerStyle(.segmented)

            ScrollView {
                Group {
                    if let markdown = try? AttributedString(markdown: tab == 0 ? helpMarkdown : changelogMarkdown) {
                        Text(markdown)
                    } else {
                        Text(tab == 0 ? helpMarkdown : changelogMarkdown)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Spacer()
        }
        .padding(20)
        .navigationTitle("About")
    }

    private var helpMarkdown: String {
        loadMarkdown(named: "help.md") ?? "Help content is unavailable."
    }

    private var changelogMarkdown: String {
        loadMarkdown(named: "changelog.md") ?? "No changelog entries."
    }

    private func loadMarkdown(named filename: String) -> String? {
        guard let url = Bundle.module.url(forResource: filename, withExtension: nil, subdirectory: "md") else {
            return nil
        }

        return try? String(contentsOf: url, encoding: .utf8)
    }
}
