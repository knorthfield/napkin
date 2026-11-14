/// Finds the part of a Markdown line that the calculator reads.
enum MarkdownLine {
    /// A line that starts or ends a fenced code block.
    static func isCodeFence(_ line: Substring) -> Bool {
        let text = line.drop(while: \.isWhitespace)
        return text.hasPrefix("```") || text.hasPrefix("~~~")
    }

    /// The line without its list marker and label, or nil if the line is only text:
    /// a heading, a quote, a table row, a rule or a `//` comment.
    static func expression(in line: Substring) -> Substring? {
        var text = line.drop(while: \.isWhitespace)
        if text.hasPrefix("//") || text.hasPrefix(">") || text.hasPrefix("|") { return nil }
        let heading = text.prefix(while: { $0 == "#" })
        if (1...6).contains(heading.count), text.dropFirst(heading.count).first?.isWhitespace ?? true { return nil }
        if let first = text.first, "-*_".contains(first),
           text.allSatisfy({ $0 == first || $0.isWhitespace }), text.filter({ $0 == first }).count >= 3 {
            return nil
        }

        text = text.dropFirst(listMarkerLength(of: text))
        for checkbox in ["[ ] ", "[x] ", "[X] "] where text.hasPrefix(checkbox) {
            text = text.dropFirst(checkbox.count)
        }
        if let colon = labelEnd(in: text) { text = text[text.index(after: colon)...] }
        return text
    }

    /// The length of `- `, `* `, `+ `, `1. ` or `1) ` at the start of the text, or 0.
    private static func listMarkerLength(of text: Substring) -> Int {
        guard let first = text.first else { return 0 }
        var length = 0
        if "-*+".contains(first) {
            length = 1
        } else {
            let digits = text.prefix(while: { $0.isASCII && $0.isNumber }).count
            guard digits > 0, let end = text.dropFirst(digits).first, end == "." || end == ")" else { return 0 }
            length = digits + 1
        }
        return text.dropFirst(length).first == " " ? length + 1 : 0
    }

    /// The colon that ends a label such as `Price:`. A colon in a clock time (`2:30`) is not a label.
    private static func labelEnd(in text: Substring) -> Substring.Index? {
        var index = text.startIndex
        while index < text.endIndex {
            let next = text.index(after: index)
            if text[index] == "\"" { return nil }
            if text[index] == ":", next == text.endIndex || text[next] == " " { return index }
            index = next
        }
        return nil
    }
}
