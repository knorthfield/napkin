/// The result of one line of a note.
struct LineResult: Equatable, Sendable {
    /// The text for the results column, or nil if the line has no result.
    var display: String?
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
            if line.allSatisfy(\.isWhitespace) {
                state.block = []
                return LineResult()
            }
            if MarkdownLine.isCodeFence(line) {
                isInsideCodeBlock.toggle()
                return LineResult()
            }
            guard !isInsideCodeBlock, let expression = MarkdownLine.expression(in: line) else { return LineResult() }

            var tokens = Lexer.tokens(of: expression)
            var assignedName: String?
            if tokens.count > 2, case .word(let name) = tokens[0].kind, tokens[1].kind == .symbol("="),
               !LineEvaluator.isReserved(name) {
                assignedName = name
                tokens.removeFirst(2)
            }
            var evaluator = LineEvaluator(tokens: tokens, state: state, context: context)
            guard let value = evaluator.evaluate() else { return LineResult() }
            if let assignedName { state.variables[assignedName] = value }
            state.previous = value
            // A total is not a part of the next total.
            if !evaluator.usesBlock { state.block.append(value) }
            return LineResult(display: ResultFormatter.string(for: value, context: context))
        }
    }
}
