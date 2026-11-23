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
    /// The value that the total of the note adds, or nil. A line that uses `sum` or `total` adds nothing.
    var valueForTotal: Value?
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
                if result.headingLevel != nil, let marksEnd = line.firstIndex(where: { $0 != "#" && !$0.isWhitespace }) {
                    result.spans = [.init(range: line.startIndex..<marksEnd, role: .mark)]
                }
                if line.drop(while: \.isWhitespace).hasPrefix("//") { result.spans = [.init(range: result.range, role: .comment)] }
                return result
            }
            // The list marker and the label.
            if expression.startIndex > line.startIndex {
                result.spans.append(.init(range: line.startIndex..<expression.startIndex, role: .comment))
            }

            var tokens = Lexer.tokens(of: expression)
            var assignedName: String?
            if tokens.count > 2, case .word(let name) = tokens[0].kind, tokens[1].kind == .symbol("="),
               !LineEvaluator.isReserved(name) {
                assignedName = name
            }
            var evaluator = LineEvaluator(tokens: Array(tokens.dropFirst(assignedName == nil ? 0 : 2)), state: state, context: context)
            let value = evaluator.evaluate()
            // A line with no result is a sentence: only its comments and Markdown marks get a colour.
            let roles = (assignedName == nil ? [] : [.variable, .keyword]) + evaluator.roles
            for (token, role) in zip(tokens, roles) {
                if let role, value != nil || role == .comment || role == .mark {
                    result.spans.append(.init(range: token.range, role: role))
                }
            }
            guard let value else { return result }
            if let assignedName { state.variables[assignedName] = value }
            state.previous = value
            // A total is not a part of the next total.
            if !evaluator.usesBlock {
                state.block.append(value)
                result.valueForTotal = value
            }
            result.display = ResultFormatter.string(for: value, context: context)
            return result
        }
    }

    /// The sum of all the results of a note, or nil if it has none. A result that cannot be added is skipped.
    static func total(of results: [LineResult], context: EvaluationContext = EvaluationContext()) -> String? {
        var sum: Value?
        for value in results.compactMap(\.valueForTotal) {
            sum = sum.map { $0.applying(.add, value) ?? $0 } ?? value
        }
        return sum.map { ResultFormatter.string(for: $0, context: context) }
    }
}
