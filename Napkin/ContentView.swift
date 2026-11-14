import SwiftUI

struct ContentView: View {
    var store: NoteStore

    var body: some View {
        NavigationSplitView {
            NotesSidebar(store: store)
        } detail: {
            if let note = store.selectedNote {
                NoteEditor(text: note.text, results: Calculator.evaluate(note.text)) { text in
                    store.setText(text, of: note.url)
                }
                // A different note is a different editor, with its own caret and undo history.
                .id(note.url)
            } else {
                ContentUnavailableView("No Notes", systemImage: "square.and.pencil",
                                       description: Text("Make a note with ⌘N."))
            }
        }
    }
}
