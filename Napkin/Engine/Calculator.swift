/// The result of one line of a note.
struct LineResult: Equatable, Sendable {
    /// A part of the line with a colour of its own.
    struct Span: Equatable, Sendable {
        var range: Range<String.Index>
        var role: TokenRole
    }

    /// The place of the line in the text of the note.
    var range: Range<String.Index>
    /// The text for the results column, or nil if the line has no result.
    var display: String?
    /// 1 to 6 for a Markdown heading.
    var headingLevel: Int?
    var spans: [Span] = []
}

/// What the lines above give to a line.
struct DocumentState: Sendable {
    var variables: [String: Value] = [:]
    /// The last result above the line.
    var previous: Value?
    /// The results above the line, up to the first empty line.
    var block: [Value] = []
}

/// Calculates all the lines of a note, from the top down.
enum Calculator {
    static func evaluate(_ text: String, context: EvaluationContext = EvaluationContext()) -> [LineResult] {
        var state = DocumentState()
        var isInsideCodeBlock = false
        return text.split(separator: "\n", omittingEmptySubsequences: false).map { line in
            var result = LineResult(range: line.startIndex..<line.endIndex)
            if line.allSatisfy(\.isWhitespace) {
                state.block = []
                return result
            }
            if MarkdownLine.isCodeFence(line) {
                isInsideCodeBlock.toggle()
                return result
            }
            if isInsideCodeBlock { return result }
            guard let expression = MarkdownLine.expression(in: line) else {
                result.headingLevel = MarkdownLine.headingLevel(of: line)
                if line.drop(while: \.isWhitespace).hasPrefix("//") { result.spans = [.init(range: result.range, role: .comment)] }
                return result
            }
            // The list marker and the label.
            if expression.startIndex > line.startIndex {
                result.spans.append(.init(range: line.startIndex..<expression.startIndex, role: .mark))
            }

            var tokens = Lexer.tokens(of: expression)
            var assignedName: String?
            if tokens.count > 2, case .word(let name) = tokens[0].kind, tokens[1].kind == .symbol("="),
               !LineEvaluator.isReserved(name) {
                assignedName = name
                result.spans.append(.init(range: tokens[0].range, role: .variable))
                result.spans.append(.init(range: tokens[1].range, role: .keyword))
                tokens.removeFirst(2)
            }
            var evaluator = LineEvaluator(tokens: tokens, state: state, context: context)
            for (token, role) in zip(tokens, evaluator.roles) {
                if let role { result.spans.append(.init(range: token.range, role: role)) }
            }
            guard let value = evaluator.evaluate() else { return result }
            if let assignedName { state.variables[assignedName] = value }
            state.previous = value
            // A total is not a part of the next total.
            if !evaluator.usesBlock { state.block.append(value) }
            result.display = ResultFormatter.string(for: value, context: context)
            return result
        }
    }
}
