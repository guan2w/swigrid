import SwiftUI
import Foundation
import UIKit

struct MarkdownTextView: View {
    let markdown: String

    var body: some View {
        Text(buildAttributedString(markdown))
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func buildAttributedString(_ md: String) -> AttributedString {
        guard let nsAttrStr = try? NSAttributedString(
            markdown: md,
            options: .init(
                allowsExtendedAttributes: true,
                interpretedSyntax: .full,
                failurePolicy: .returnPartiallyParsedIfPossible
            )
        ) else {
            return AttributedString(md)
        }

        // 1. Manually insert newlines and list indent/bullets between block-level elements
        let mut = NSMutableAttributedString(attributedString: nsAttrStr)
        let fullRange = NSRange(location: 0, length: mut.length)
        var insertions: [(Int, String)] = []
        var lastComponents: [PresentationIntent.Kind] = []
        var processedListItems = Set<Int>()

        mut.enumerateAttribute(.presentationIntentAttributeName, in: fullRange, options: []) { val, range, _ in
            guard let intent = val as? PresentationIntent else {
                lastComponents = []
                return
            }
            
            let components = intent.components.map(\.kind)
            // Don't insert separating spacing if the run itself contains only whitespace/newline
            // Wait, we DO want block spacing. But we skip calculating if it's empty string.
            // Actually, inserting is safe.
            var insertString = ""
            
            // Handle block separating newlines
            if !lastComponents.isEmpty, lastComponents != components {
                let lastIsListItem = lastComponents.contains(where: { String(describing: $0).starts(with: "listItem") })
                let currentIsListItem = components.contains(where: { String(describing: $0).starts(with: "listItem") })
                
                // Between list items, use a single newline. Otherwise, use double newlines.
                insertString += (lastIsListItem && currentIsListItem) ? "\n" : "\n\n"
            }
            lastComponents = components
            
            // Handle list item bullets
            if let listItemIdx = intent.components.firstIndex(where: { String(describing: $0).starts(with: "listItem") }) {
                let listItemComp = intent.components[listItemIdx]
                if !processedListItems.contains(listItemComp.identity) {
                    processedListItems.insert(listItemComp.identity)
                    
                    let depth = intent.components.filter { 
                        let desc = String(describing: $0.kind)
                        return desc.starts(with: "unorderedList") || desc.starts(with: "orderedList")
                    }.count
                    
                    let indent = String(repeating: "   ", count: max(0, depth - 1))
                    let parentKind = (listItemIdx + 1 < intent.components.count) ? intent.components[listItemIdx + 1].kind : .paragraph
                    
                    let bullet: String
                    if case .orderedList = parentKind {
                        if case .listItem(let ordinal) = listItemComp.kind {
                            bullet = "\(ordinal). "
                        } else {
                            bullet = "1. "
                        }
                    } else {
                        // Alternate bullet points based on depth
                        bullet = depth % 2 == 0 ? "◦ " : "• "
                    }
                    
                    insertString += "\(indent)\(bullet)"
                }
            }
            
            if !insertString.isEmpty {
                insertions.append((range.location, insertString))
            }
        }

        // Insert from end to beginning to preserve range locations
        for (location, text) in insertions.reversed() {
            mut.insert(NSAttributedString(string: text), at: location)
        }

        // 2. Convert to SwiftUI AttributedString and apply styling
        guard var attrStr = try? AttributedString(mut, including: \.swiftUI) else {
            return AttributedString(md)
        }

        for run in attrStr.runs {
            if let intent = run.presentationIntent {
                for comp in intent.components {
                    switch comp.kind {
                    case .header(let level):
                        switch level {
                        case 1: attrStr[run.range].font = .system(size: 26, weight: .bold)
                        case 2: attrStr[run.range].font = .system(size: 22, weight: .semibold)
                        case 3: attrStr[run.range].font = .system(size: 18, weight: .semibold)
                        default: attrStr[run.range].font = .system(size: 15, weight: .medium)
                        }
                    case .blockQuote:
                        attrStr[run.range].foregroundColor = .secondary
                    case .paragraph:
                        // Just ensure body font
                        if attrStr[run.range].font == nil {
                            attrStr[run.range].font = .body
                        }
                    case .listItem:
                        // Prepend a bullet since NSAttributedString removes the raw markdown bullets
                        // We can't insert easily during runs iteration without messing up indices,
                        // so we just rely on custom styling if needed.
                        break
                    default:
                        break
                    }
                }
            }
        }

        return attrStr
    }
}

// Keeping the _SizingMarkdownView struct temporarily named here just so callers don't break
struct _SizingMarkdownView: View {
    let markdown: String
    let width: CGFloat

    var body: some View {
        MarkdownTextView(markdown: markdown)
    }
}
