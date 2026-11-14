import Foundation
import Testing
@testable import Napkin

@MainActor
struct NoteStoreTests {
    private let folder = FileManager.default.temporaryDirectory.appending(path: "NapkinTests-\(UUID().uuidString)")

    private func write(_ text: String, to name: String) throws {
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try text.write(to: folder.appending(path: name), atomically: true, encoding: .utf8)
    }

    @Test func theFirstLaunchMakesTheFolderAndASampleNote() {
        let store = NoteStore(folder: folder)
        #expect(store.notes.count == 1)
        #expect(store.notes[0].title == "Welcome to Napkin")
        #expect(store.selection == store.notes[0].url)
        #expect(NoteStore(folder: folder).notes.count == 1)
    }

    @Test func notesAreMarkdownFilesNewestFirst() throws {
        try write("old", to: "2026-01-01 09.00.00.md")
        try write("new", to: "2026-02-01 09.00.00.md")
        try write("not a note", to: "readme.txt")
        #expect(NoteStore(folder: folder).notes.map(\.text) == ["new", "old"])
    }

    @Test func aChangeIsSavedImmediatelyWithExactlyTheTypedText() throws {
        try write("", to: "2026-01-01 09.00.00.md")
        let store = NoteStore(folder: folder)
        let url = try #require(store.notes.first?.url)
        store.setText("# Budget\n- 2 + 2\n", of: url)
        #expect(try String(contentsOf: url, encoding: .utf8) == "# Budget\n- 2 + 2\n")
        #expect(NoteStore(folder: folder).notes[0].text == "# Budget\n- 2 + 2\n")
    }

    @Test func newNotesGetDifferentFilesAndTheSelection() throws {
        try write("first", to: "2026-01-01 09.00.00.md")
        let store = NoteStore(folder: folder)
        store.addNote()
        store.addNote()
        #expect(store.notes.count == 3)
        #expect(Set(store.notes.map(\.url)).count == 3)
        #expect(store.selection == store.notes[0].url)
        #expect(store.notes[0].text == "")
    }

    @Test func deleteRemovesTheFileAndSelectsANeighbour() throws {
        try write("a", to: "2026-01-01 09.00.00.md")
        try write("b", to: "2026-02-01 09.00.00.md")
        let store = NoteStore(folder: folder)
        let deleted = store.notes[0].url
        store.delete(deleted)
        #expect(store.notes.map(\.text) == ["a"])
        #expect(store.selection == store.notes[0].url)
        #expect(!FileManager.default.fileExists(atPath: deleted.path))
    }

    @Test func loadReadsChangesFromOtherApps() throws {
        try write("before", to: "2026-01-01 09.00.00.md")
        let store = NoteStore(folder: folder)
        try write("after", to: "2026-01-01 09.00.00.md")
        store.load()
        #expect(store.notes.map(\.text) == ["after"])
    }

    @Test(arguments: [
        ("# Budget\n1 + 1", "Budget"), ("\n\n- milk", "milk"), ("1. first", "first"), ("", "New Note"),
        ("  \n", "New Note"), ("2 + 2", "2 + 2"), ("-5", "-5"),
    ])
    func titles(text: String, title: String) {
        #expect(Note(url: URL(filePath: "/tmp/a.md"), text: text).title == title)
    }
}
