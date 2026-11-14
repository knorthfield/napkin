import Foundation

/// One note: a Markdown file. The file has exactly the text that the user typed.
struct Note: Identifiable, Equatable {
    let url: URL
    var text: String

    var id: URL { url }

    /// The first line that is not empty, without its heading or list marker.
    var title: String {
        for line in text.split(separator: "\n") {
            let title = line.trimmingPrefix(/\s*(#{1,6}\s|[-*+]\s|\d+[.)]\s)?\s*/).trimmingCharacters(in: .whitespaces)
            if !title.isEmpty { return title }
        }
        return "New Note"
    }
}
