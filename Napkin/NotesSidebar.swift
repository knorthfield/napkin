import SwiftUI

/// The list of notes, newest first.
struct NotesSidebar: View {
    @Bindable var store: NoteStore

    var body: some View {
        List(store.notes, selection: $store.selection) { note in
            Text(note.title)
                .lineLimit(1)
                .contextMenu {
                    Button("Delete", role: .destructive) { store.delete(note.url) }
                }
        }
        .onDeleteCommand {
            if let selection = store.selection { store.delete(selection) }
        }
        .navigationSplitViewColumnWidth(min: 160, ideal: 200, max: 320)
        .toolbar {
            Button("New Note", systemImage: "square.and.pencil") { store.addNote() }
                .keyboardShortcut("n")
                .help("New Note")
        }
    }
}
