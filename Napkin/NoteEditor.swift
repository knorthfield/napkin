import SwiftUI

/// The editor of one note, for SwiftUI.
struct NoteEditor: NSViewRepresentable {
    var text: String
    var results: [LineResult]
    var total: String?
    var onTextChange: (String) -> Void

    func makeNSView(context: Context) -> EditorView {
        EditorView(frame: .zero)
    }

    func updateNSView(_ view: EditorView, context: Context) {
        view.onTextChange = onTextChange
        view.show(text: text, results: results, total: total)
    }
}
