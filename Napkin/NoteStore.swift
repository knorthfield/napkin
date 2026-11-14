import Foundation
import Observation

/// The notes in the Napkin folder, newest first. Each change is saved immediately.
@MainActor @Observable
final class NoteStore {
    static let defaultFolder = URL.documentsDirectory.appending(path: "Napkin", directoryHint: .isDirectory)
    private static let selectedNoteKey = "SelectedNote"

    private(set) var notes: [Note] = []
    var selection: URL? {
        didSet { UserDefaults.standard.set(selection?.lastPathComponent, forKey: Self.selectedNoteKey) }
    }

    @ObservationIgnored private let folder: URL

    init(folder: URL = NoteStore.defaultFolder) {
        self.folder = folder
        let isFirstLaunch = !FileManager.default.fileExists(atPath: folder.path)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        if isFirstLaunch { addNote(text: Self.sampleText) }
        load()
        let lastSelected = UserDefaults.standard.string(forKey: Self.selectedNoteKey)
        selection = (notes.first { $0.url.lastPathComponent == lastSelected } ?? notes.first)?.url
    }

    var selectedNote: Note? {
        notes.first { $0.url == selection }
    }

    /// Reads the folder again. Another app can change the files while Napkin is in the background.
    func load() {
        let files = (try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)) ?? []
        notes = files
            .filter { $0.pathExtension == "md" }
            .sorted { $0.lastPathComponent > $1.lastPathComponent }
            .compactMap { url in (try? String(contentsOf: url, encoding: .utf8)).map { Note(url: url, text: $0) } }
        if selectedNote == nil { selection = notes.first?.url }
    }

    /// Makes a file with the time as its name, such as `2026-11-14 12.05.01.md`, and selects it.
    func addNote(text: String = "") {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH.mm.ss"
        let name = formatter.string(from: .now)
        var url = folder.appending(path: "\(name).md")
        var copy = 2
        while FileManager.default.fileExists(atPath: url.path) {
            url = folder.appending(path: "\(name) \(copy).md")
            copy += 1
        }
        let note = Note(url: url, text: text)
        save(note)
        notes.insert(note, at: 0)
        selection = url
    }

    func setText(_ text: String, of url: URL) {
        guard let index = notes.firstIndex(where: { $0.url == url }), notes[index].text != text else { return }
        notes[index].text = text
        save(notes[index])
    }

    /// Moves the file to the Trash.
    func delete(_ url: URL) {
        guard let index = notes.firstIndex(where: { $0.url == url }) else { return }
        try? FileManager.default.trashItem(at: url, resultingItemURL: nil)
        notes.remove(at: index)
        if selection == url { selection = (notes.indices.contains(index) ? notes[index] : notes.last)?.url }
    }

    private func save(_ note: Note) {
        try? note.text.write(to: note.url, atomically: true, encoding: .utf8)
    }

    private static let sampleText = """
        # Welcome to Napkin

        Write a calculation on each line. The result shows on the right.
        Click a result to copy it.

        ## Holiday budget
        Flights: $420 + $380
        Hotel: 6 nights times 95 EUR
        Food: 7 days * $60
        total in GBP

        ## Other examples
        20% of 340
        rate = 12.5
        40 hours * rate
        5 ft 11 inches in cm
        350 °F in °C
        2 GB in MB
        today + 3 weeks
        9:30 am New York in London
        sqrt(2) * 10
        255 in hex
        """
}
