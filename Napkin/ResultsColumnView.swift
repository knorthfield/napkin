import AppKit

/// Draws the results. A click on a result copies it.
final class ResultsColumnView: NSView {
    struct Row: Equatable {
        /// The top of the row in this view.
        var y: CGFloat
        var height: CGFloat
        var text: String
    }

    var rows: [Row] = [] {
        didSet { if rows != oldValue { needsDisplay = true } }
    }
    /// The row that shows "Copied" for a moment after a click.
    private var copiedRowY: CGFloat?

    override var isFlipped: Bool { true }

    private static let padding: CGFloat = 14

    override func draw(_ dirtyRect: NSRect) {
        let style = NSMutableParagraphStyle()
        style.alignment = .right
        style.lineBreakMode = .byTruncatingTail
        for row in rows {
            let isCopied = row.y == copiedRowY
            NSAttributedString(string: isCopied ? "Copied" : row.text, attributes: [
                .font: EditorView.font,
                .foregroundColor: isCopied ? NSColor.secondaryLabelColor : NSColor.controlAccentColor,
                .paragraphStyle: style,
            ]).draw(in: NSRect(x: Self.padding, y: row.y, width: bounds.width - 2 * Self.padding, height: row.height))
        }
    }

    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        guard let row = rows.first(where: { ($0.y...$0.y + $0.height).contains(point.y) }) else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(row.text, forType: .string)
        copiedRowY = row.y
        needsDisplay = true
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(0.8))
            self?.copiedRowY = nil
            self?.needsDisplay = true
        }
    }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .pointingHand)
    }
}
