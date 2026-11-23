import AppKit
import Testing
@testable import Napkin

@MainActor
struct EditorLayoutTests {
    private func editor(text: String) -> EditorView {
        let editor = EditorView(frame: NSRect(x: 0, y: 0, width: 400, height: 600))
        editor.layoutSubtreeIfNeeded()
        let results = Calculator.evaluate(text)
        editor.show(text: text, results: results, total: Calculator.total(of: results))
        editor.layoutSubtreeIfNeeded()
        return editor
    }

    private func rows(of editor: EditorView) -> [ResultsColumnView.Row] {
        editor.subviews.compactMap { $0 as? ResultsColumnView }.first?.rows ?? []
    }

    @Test func eachResultIsAtTheHeightOfItsLine() {
        let rows = rows(of: editor(text: "1 + 1\n\ntext\n2 + 2"))
        #expect(rows.map(\.text) == ["2", "4"])
        #expect(rows[1].y - rows[0].y == 3 * rows[0].height)
    }

    @Test func aResultAfterAWrappedLineIsBelowAllItsRows() {
        let long = "1 + " + String(repeating: "many words that mean nothing ", count: 8)
        let rows = rows(of: editor(text: "\(long)\n2 + 2"))
        #expect(rows.map(\.text) == ["1", "4"])
        #expect(rows[1].y - rows[0].y >= 3 * rows[0].height)
    }

    @Test func theTextViewStaysOnTextKit2() {
        let editor = editor(text: "1 + 1")
        editor.textView.insertText("\n2 + 2", replacementRange: NSRange(location: 5, length: 0))
        #expect(editor.textView.textLayoutManager != nil)
    }

    @Test func syntaxColoursAndHeadingFonts() throws {
        let editor = editor(text: "# Budget\nrent = 2 km + sqrt 4 \"note\"\nCost: 5\nturn on the light")
        let storage = try #require(editor.textView.textStorage)
        func color(at text: String) -> NSColor? {
            storage.attribute(.foregroundColor, at: (storage.string as NSString).range(of: text).location, effectiveRange: nil) as? NSColor
        }
        func font(at text: String) -> NSFont? {
            storage.attribute(.font, at: (storage.string as NSString).range(of: text).location, effectiveRange: nil) as? NSFont
        }
        #expect(font(at: "Budget")?.pointSize == (EditorView.font.pointSize * 1.5).rounded())
        #expect(font(at: "rent") == EditorView.font)
        #expect(color(at: "rent") == .systemPurple)
        #expect(color(at: "=") == .systemOrange)
        #expect(color(at: "2") == .labelColor)
        #expect(color(at: "km") == .systemTeal)
        #expect(color(at: "+") == .systemOrange)
        #expect(color(at: "sqrt") == .systemBlue)
        #expect(color(at: "\"note\"") == .secondaryLabelColor)
        #expect(color(at: "#") == .tertiaryLabelColor)
        #expect(color(at: "Cost:") == .secondaryLabelColor)
        #expect(color(at: "on the") == .labelColor)
        #expect(editor.textView.textLayoutManager != nil)
        #expect(rows(of: editor).map(\.text) == ["4 km", "5"])
    }

    @Test func theResultAtTheCaretIsTheResultOfItsLine() {
        let editor = editor(text: "1 + 1\n2 + 2\ntext")
        editor.textView.setSelectedRange(NSRange(location: 8, length: 0))
        #expect(editor.resultAtCaret == "4")
        editor.textView.setSelectedRange(NSRange(location: 14, length: 0))
        #expect(editor.resultAtCaret == nil)
    }

    @Test func thePrintedNoteHasEachResultAfterItsLineAndTheTotalAtTheEnd() {
        let page = editor(text: "1 + 1\ntext\n2 * 3").printView(for: NSPrintInfo())
        #expect(page.string == "1 + 1\t2\ntext\n2 * 3\t6\n\nTotal\t8")
    }
}
