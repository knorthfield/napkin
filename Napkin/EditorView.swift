import AppKit

/// The text of a note on the left and the result of each line on the right.
/// Each result stays at the height of the first row of its line, also when the line wraps.
final class EditorView: NSView, NSTextViewDelegate {
    static let font = NSFont.monospacedDigitSystemFont(ofSize: 15, weight: .regular)

    var onTextChange: (String) -> Void = { _ in }

    let textView: NSTextView
    private let scrollView: NSScrollView
    private let resultsColumn = ResultsColumnView()
    private var results: [LineResult] = []
    /// The line number for the UTF-16 offset at which each line starts.
    private var lineNumbers: [Int: Int] = [:]

    override init(frame: NSRect) {
        scrollView = NSTextView.scrollableTextView()
        textView = scrollView.documentView as! NSTextView
        super.init(frame: frame)

        textView.delegate = self
        textView.isRichText = false
        textView.allowsUndo = true
        textView.font = Self.font
        textView.textContainerInset = NSSize(width: 14, height: 14)
        textView.drawsBackground = false
        // A calculation must keep the characters that the user typed.
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isAutomaticDataDetectionEnabled = false
        textView.isAutomaticLinkDetectionEnabled = false
        textView.isContinuousSpellCheckingEnabled = false
        textView.isGrammarCheckingEnabled = false
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = true
        addSubview(scrollView)
        addSubview(resultsColumn)

        // The results move with the text when it scrolls and when its lines wrap differently.
        scrollView.contentView.postsBoundsChangedNotifications = true
        textView.postsFrameChangedNotifications = true
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(placeResults), name: NSView.boundsDidChangeNotification,
                           object: scrollView.contentView)
        center.addObserver(self, selector: #selector(placeResults), name: NSView.frameDidChangeNotification,
                           object: textView)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func layout() {
        super.layout()
        let resultsWidth = min(max(bounds.width * 0.3, 120), 320)
        scrollView.frame = NSRect(x: 0, y: 0, width: bounds.width - resultsWidth, height: bounds.height)
        resultsColumn.frame = NSRect(x: bounds.width - resultsWidth, y: 0, width: resultsWidth, height: bounds.height)
        placeResults()
    }

    /// Shows a note. The caret and the undo history stay when the text is already the same.
    func show(text: String, results: [LineResult]) {
        if textView.string != text {
            textView.string = text
            textView.undoManager?.removeAllActions()
        }
        self.results = results
        lineNumbers = [:]
        var offset = 0
        for (number, line) in text.split(separator: "\n", omittingEmptySubsequences: false).enumerated() {
            lineNumbers[offset] = number
            offset += line.utf16.count + 1
        }
        placeResults()
    }

    func textDidChange(_ notification: Notification) {
        onTextChange(textView.string)
    }

    /// The result of the line with the caret, for the Copy Result command.
    var resultAtCaret: String? {
        let text = textView.string as NSString
        let caret = min(textView.selectedRange().location, text.length)
        let lineStart = text.lineRange(for: NSRange(location: caret, length: 0)).location
        guard let line = lineNumbers[lineStart], results.indices.contains(line) else { return nil }
        return results[line].display
    }

    @objc private func placeResults() {
        // Use the TextKit 2 layout only. `layoutManager` would change the text view to TextKit 1.
        guard let layoutManager = textView.textLayoutManager, let content = layoutManager.textContentManager else { return }
        let origin = textView.textContainerOrigin
        let visible = textView.visibleRect
        let firstVisible = layoutManager.textLayoutFragment(for: CGPoint(x: 0, y: visible.minY - origin.y))
        var rows: [ResultsColumnView.Row] = []
        layoutManager.enumerateTextLayoutFragments(
            from: firstVisible?.rangeInElement.location ?? layoutManager.documentRange.location,
            options: [.ensuresLayout]
        ) { fragment in
            let top = fragment.layoutFragmentFrame.minY + origin.y
            if top > visible.maxY { return false }
            let offset = content.offset(from: layoutManager.documentRange.location, to: fragment.rangeInElement.location)
            if let line = self.lineNumbers[offset], self.results.indices.contains(line),
               let display = self.results[line].display, let firstRow = fragment.textLineFragments.first {
                let rowTop = top + firstRow.typographicBounds.minY
                let y = self.resultsColumn.convert(NSPoint(x: 0, y: rowTop), from: self.textView).y
                rows.append(ResultsColumnView.Row(y: y, height: firstRow.typographicBounds.height, text: display))
            }
            return true
        }
        resultsColumn.rows = rows
    }
}
