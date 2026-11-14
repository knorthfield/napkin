import AppKit

/// Gives the text of a note its colours and its heading fonts. It does not hide or change characters.
@MainActor
enum SyntaxHighlighter {
    static func apply(_ results: [LineResult], of text: String, to textView: NSTextView) {
        // While the user composes a character (for example with an accent), the text must stay as it is.
        guard let storage = textView.textStorage, let content = textView.textContentStorage,
              storage.string == text, !textView.hasMarkedText() else { return }
        let plain: [NSAttributedString.Key: Any] = [.font: EditorView.font, .foregroundColor: NSColor.labelColor]
        content.performEditingTransaction {
            storage.setAttributes(plain, range: NSRange(location: 0, length: storage.length))
            for line in results {
                if let level = line.headingLevel {
                    storage.addAttribute(.font, value: headingFont(level: level), range: NSRange(line.range, in: text))
                }
                for span in line.spans {
                    storage.addAttribute(.foregroundColor, value: color(for: span.role), range: NSRange(span.range, in: text))
                }
            }
        }
        // Without this, text typed after a heading would keep the heading's font.
        textView.typingAttributes = plain
    }

    private static func headingFont(level: Int) -> NSFont {
        let scale: CGFloat = level == 1 ? 1.5 : level == 2 ? 1.25 : 1
        return NSFont.systemFont(ofSize: (EditorView.font.pointSize * scale).rounded(), weight: .bold)
    }

    private static func color(for role: TokenRole) -> NSColor {
        switch role {
        case .number: .labelColor
        case .keyword: .systemOrange
        case .unit: .systemTeal
        case .variable: .systemPurple
        case .function: .systemBlue
        case .comment: .secondaryLabelColor
        case .mark: .tertiaryLabelColor
        }
    }
}
