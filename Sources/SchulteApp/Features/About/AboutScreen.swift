import SwiftUI

struct AboutScreen: View {
    @State private var tab = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Swigrid")
                .font(.system(size: 36, weight: .bold, design: .serif))

            Text("Train your focus and visual scanning skills with a fluid native iOS experience.")
                .foregroundStyle(.secondary)

            Picker("Content", selection: $tab) {
                Text("How to Play").tag(0)
                Text("What's New").tag(1)
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
        .navigationTitle("About")
        .edgeOnlySwipeBack()
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
