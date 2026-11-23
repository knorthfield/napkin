import AppKit

/// The text of a note on the left and the result of each line on the right.
/// Each result stays at the height of the first row of its line, also when the line wraps.
final class EditorView: NSView, NSTextViewDelegate {
    static let font = NSFont.monospacedDigitSystemFont(ofSize: 15, weight: .regular)

    var onTextChange: (String) -> Void = { _ in }
    /// The name of a printed or saved PDF.
    var title = ""

    let textView: NSTextView
    private let scrollView: NSScrollView
    private let resultsColumn = ResultsColumnView()
    private let totalFooter = TotalFooterView()
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
        addSubview(totalFooter)

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

    /// A new editor takes the keyboard, unless the user is in a different view such as the list of notes.
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        DispatchQueue.main.async { [weak self] in
            guard let self, let window, window.firstResponder === window else { return }
            window.makeFirstResponder(textView)
        }
    }

    override func layout() {
        super.layout()
        let resultsWidth = min(max(bounds.width * 0.3, 120), 320)
        let footerHeight = totalFooter.total == nil ? 0 : TotalFooterView.height
        totalFooter.frame = NSRect(x: 0, y: 0, width: bounds.width, height: footerHeight)
        let height = bounds.height - footerHeight
        scrollView.frame = NSRect(x: 0, y: footerHeight, width: bounds.width - resultsWidth, height: height)
        resultsColumn.frame = NSRect(x: bounds.width - resultsWidth, y: footerHeight, width: resultsWidth, height: height)
        placeResults()
    }

    /// Shows a note. The caret and the undo history stay when the text is already the same.
    func show(text: String, results: [LineResult], total: String?) {
        if textView.string != text {
            textView.string = text
            textView.undoManager?.removeAllActions()
        }
        self.results = results
        if total != totalFooter.total {
            // The footer shows only when the note has a total.
            if (total == nil) != (totalFooter.total == nil) { needsLayout = true }
            totalFooter.total = total
        }
        SyntaxHighlighter.apply(results, of: text, to: textView)
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

    /// The result of the line with the caret.
    var resultAtCaret: String? {
        caretLine.flatMap { results.indices.contains($0) ? results[$0].display : nil }
    }

    private var caretLine: Int? {
        let text = textView.string as NSString
        let caret = min(textView.selectedRange().location, text.length)
        return lineNumbers[text.lineRange(for: NSRange(location: caret, length: 0)).location]
    }

    /// The Copy Result command: copies the result of the line with the caret.
    @objc func copyResult(_ sender: Any?) {
        guard let result = resultAtCaret else { return NSSound.beep() }
        if let row = resultsColumn.rows.first(where: { $0.line == caretLine }) {
            resultsColumn.copy(row)
        } else {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(result, forType: .string)
        }
    }

    /// The Print command. The print panel can also save the note as a PDF.
    @objc func printNote(_ sender: Any?) {
        let printInfo = NSPrintInfo.shared.copy() as! NSPrintInfo
        printInfo.horizontalPagination = .fit
        printInfo.isVerticallyCentered = false
        let operation = NSPrintOperation(view: printView(for: printInfo), printInfo: printInfo)
        operation.jobTitle = title
        if let window { operation.runModal(for: window, delegate: nil, didRun: nil, contextInfo: nil) } else { operation.run() }
    }

    /// The note for the page: each result at the right of its line, and the total at the end.
    func printView(for printInfo: NSPrintInfo) -> NSTextView {
        let width = printInfo.paperSize.width - printInfo.leftMargin - printInfo.rightMargin
        let style = NSMutableParagraphStyle()
        style.tabStops = [NSTextTab(textAlignment: .right, location: width)]
        let resultAttributes: [NSAttributedString.Key: Any] = [.font: Self.font, .foregroundColor: NSColor.controlAccentColor]
        let page = NSMutableAttributedString()
        let note = textView.textStorage ?? NSTextStorage()
        var offset = 0
        for (number, line) in textView.string.split(separator: "\n", omittingEmptySubsequences: false).enumerated() {
            let length = line.utf16.count
            page.append(note.attributedSubstring(from: NSRange(location: offset, length: length)))
            if results.indices.contains(number), let display = results[number].display {
                page.append(NSAttributedString(string: "\t" + display, attributes: resultAttributes))
            }
            page.append(NSAttributedString(string: "\n", attributes: [.font: Self.font]))
            offset += length + 1
        }
        if let total = totalFooter.total {
            page.append(NSAttributedString(string: "\nTotal", attributes: [.font: Self.font, .foregroundColor: NSColor.secondaryLabelColor]))
            page.append(NSAttributedString(string: "\t" + total, attributes: resultAttributes))
        }
        page.addAttribute(.paragraphStyle, value: style, range: NSRange(location: 0, length: page.length))

        let view = NSTextView(frame: NSRect(x: 0, y: 0, width: width, height: 1))
        view.appearance = NSAppearance(named: .aqua)
        view.textContainerInset = .zero
        view.textContainer?.lineFragmentPadding = 0
        view.isVerticallyResizable = true
        view.textStorage?.setAttributedString(page)
        view.sizeToFit()
        return view
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
                rows.append(ResultsColumnView.Row(y: y, height: firstRow.typographicBounds.height, text: display, line: line))
            }
            return true
        }
        resultsColumn.rows = rows
    }
}

/// The sum of all the results of the note, at the bottom of the editor. A click copies it.
private final class TotalFooterView: NSView {
    static let height: CGFloat = 34

    var total: String? {
        didSet { needsDisplay = true }
    }
    private var isShowingCopied = false

    override func draw(_ dirtyRect: NSRect) {
        guard let total else { return }
        NSColor.separatorColor.setFill()
        NSRect(x: 0, y: bounds.height - 1, width: bounds.width, height: 1).fill()
        let textHeight = EditorView.font.boundingRectForFont.height
        let textRect = NSRect(x: 19, y: (bounds.height - textHeight) / 2, width: bounds.width - 19 - 14, height: textHeight)
        NSAttributedString(string: "Total", attributes: [
            .font: EditorView.font, .foregroundColor: NSColor.secondaryLabelColor,
        ]).draw(in: textRect)
        let style = NSMutableParagraphStyle()
        style.alignment = .right
        NSAttributedString(string: isShowingCopied ? "Copied" : total, attributes: [
            .font: EditorView.font,
            .foregroundColor: isShowingCopied ? NSColor.secondaryLabelColor : NSColor.controlAccentColor,
            .paragraphStyle: style,
        ]).draw(in: textRect)
    }

    override func mouseDown(with event: NSEvent) {
        guard let total else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(total, forType: .string)
        isShowingCopied = true
        needsDisplay = true
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(0.8))
            self?.isShowingCopied = false
            self?.needsDisplay = true
        }
    }

    override func resetCursorRects() {
        if total != nil { addCursorRect(bounds, cursor: .pointingHand) }
    }
}
