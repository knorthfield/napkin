import Foundation

/// Calculates the value of one line. It first gives each token a meaning (words that mean nothing are
/// ignored), then calculates while it reads the meanings, operators with a higher precedence first.
struct LineEvaluator {
    private enum Item: Equatable {
        case value(Value)
        case binary(BinaryOperator)
        case open, close
        /// `k`, `million`: multiplies the number before it.
        case scale(Double)
        /// `in`, `into`, `as`, `to`: changes how the value before it is shown.
        case convert
        case style(NumberStyle)
        case percentSign
        case percentPhrase(PercentPhrase)
        case function(String)
        case unit(UnitOfMeasure)
    }

    /// Words and groups of words with a fixed meaning. A longer phrase wins over a shorter one.
    private static let keywords: [String: Item] = [
        "+": .binary(.add), "plus": .binary(.add), "and": .binary(.add), "with": .binary(.add),
        "-": .binary(.subtract), "minus": .binary(.subtract), "subtract": .binary(.subtract),
        "without": .binary(.subtract),
        "*": .binary(.multiply), "times": .binary(.multiply), "multiplied by": .binary(.multiply),
        "mul": .binary(.multiply), "x": .binary(.multiply),
        "/": .binary(.divide), "divide": .binary(.divide), "divide by": .binary(.divide),
        "divided by": .binary(.divide),
        "^": .binary(.power), "mod": .binary(.modulo),
        "&": .binary(.bitwiseAnd), "|": .binary(.bitwiseOr), "xor": .binary(.bitwiseXor),
        "<<": .binary(.shiftLeft), ">>": .binary(.shiftRight),
        "(": .open, ")": .close,
        "%": .percentSign, "°": .unit(UnitTable.degree),
        "of": .percentPhrase(.of), "on": .percentPhrase(.on), "off": .percentPhrase(.off),
        "as a % of": .percentPhrase(.asPercentOf), "as a % on": .percentPhrase(.asPercentOn),
        "as a % off": .percentPhrase(.asPercentOff),
        "of what is": .percentPhrase(.ofWhatIs), "on what is": .percentPhrase(.onWhatIs),
        "off what is": .percentPhrase(.offWhatIs),
        "in": .convert, "into": .convert, "as": .convert, "to": .convert,
    ]
    /// One-letter scales are case-sensitive: `m` is the metre and `K` is the kelvin.
    private static let scales: [String: Double] = [
        "k": 1e3, "M": 1e6, "thousand": 1e3, "million": 1e6, "billion": 1e9, "trillion": 1e12,
    ]
    private static let styles: [String: NumberStyle] = [
        "hex": .hexadecimal, "hexadecimal": .hexadecimal, "bin": .binary, "binary": .binary,
        "oct": .octal, "octal": .octal, "sci": .scientific, "scientific": .scientific,
    ]
    private static let longestPhrase = 4

    /// Words that a note cannot use as the name of a variable.
    static func isReserved(_ name: String) -> Bool {
        let word = name.lowercased()
        return word != "x" && keywords[word] != nil || constants[word] != nil || lineReferences.contains(word)
            || Functions.names.contains(word)
    }

    private static let constants: [String: Double] = ["pi": .pi, "π": .pi, "e": M_E]
    private static let lineReferences: Set<String> = ["prev", "sum", "total", "average", "avg"]

    private let state: DocumentState
    /// True when the line uses `sum`, `total`, `average` or `avg`.
    private(set) var usesBlock = false
    private var items: [Item] = []
    private var position = 0
    /// True when the line has a meaning but no value, for example a division of text by a number.
    private var failed = false

    init(tokens: [Token], state: DocumentState) {
        self.state = state
        let texts = tokens.map(Self.text)
        var index = 0
        while index < tokens.count {
            var length = min(Self.longestPhrase, tokens.count - index)
            var keyword: Item?
            while length > 0 {
                keyword = Self.keywords[texts[index..<index + length].joined(separator: " ")]
                if keyword != nil { break }
                length -= 1
            }
            // A note can use `x` as a variable. Then it is not the multiplication sign.
            if case .word(let word) = tokens[index].kind, state.variables[word] != nil { keyword = nil }
            if let keyword {
                items.append(keyword)
                index += length
            } else if let (unit, length) = unit(at: index, in: tokens) {
                items.append(.unit(unit))
                index += length
            } else {
                if let item = meaning(of: tokens[index], after: index > 0 ? tokens[index - 1] : nil) {
                    items.append(item)
                }
                index += 1
            }
        }
    }

    /// A unit is one to three words: `km`, `sq ft`, `square nautical miles`. A word is a unit only after
    /// a value or after `in`, `into`, `as` or `to`, so that `are` and `hand` in a sentence mean nothing.
    private func unit(at index: Int, in tokens: [Token]) -> (UnitOfMeasure, Int)? {
        switch items.last {
        case .value, .scale, .close, .convert: break
        default: return nil
        }
        var words: [String] = []
        for token in tokens[index...].prefix(3) {
            guard case .word(let word) = token.kind else { break }
            words.append(word)
        }
        // A variable wins over a unit, but `em` is always the unit: the variable `em` sets its size.
        guard let first = words.first, first == "em" || state.variables[first] == nil else { return nil }
        for length in stride(from: words.count, through: 1, by: -1) {
            let name = words[..<length].joined(separator: " ")
            if let unit = screenUnit(named: name) ?? UnitTable.unit(named: name) { return (unit, length) }
        }
        return nil
    }

    /// `px` and `em` depend on the variables `ppi` (pixels in one inch, 96) and `em` (16 px).
    private func screenUnit(named name: String) -> UnitOfMeasure? {
        guard name == "px" || name == "em" else { return nil }
        var pixelsPerInch = 96.0
        if case .number(let number, _) = state.variables["ppi"] { pixelsPerInch = number }
        let pixel = UnitTable.inch.toBase / pixelsPerInch
        if name == "px" { return UnitOfMeasure(symbol: "px", dimension: .length, toBase: pixel) }
        let size: Double = switch state.variables["em"] {
        case .number(let number, _): number * pixel
        case .quantity(let number, let unit) where unit.dimension == .length: number * unit.toBase
        default: 16 * pixel
        }
        return UnitOfMeasure(symbol: "em", dimension: .length, toBase: size)
    }

    /// The meaning of a token that is not a keyword, or nil if it has none.
    private mutating func meaning(of token: Token, after previous: Token?) -> Item? {
        switch token.kind {
        case .number(let number):
            return .value(.number(number))
        case .word(let word):
            if let variable = state.variables[word], word != "em" { return .value(variable) }
            if let constant = Self.constants[word.lowercased()] { return .value(.number(constant)) }
            if Self.lineReferences.contains(word.lowercased()) { return lineReference(word.lowercased()) }
            if Functions.names.contains(word.lowercased()) { return .function(word.lowercased()) }
            if case .number = previous?.kind, let scale = Self.scales[word] ?? Self.scales[word.lowercased()],
               word.count > 1 || Self.scales[word] != nil {
                return .scale(scale)
            }
            if items.last == .convert, let style = Self.styles[word.lowercased()] { return .style(style) }
            return nil
        default:
            return nil
        }
    }

    /// `prev` is the result before this line. The others use the lines above, up to the first empty line.
    private mutating func lineReference(_ word: String) -> Item? {
        if word == "prev" { return state.previous.map(Item.value) }
        usesBlock = true
        var sum: Value?
        var count = 0.0
        for value in state.block {
            guard let next = sum.map({ $0.applying(.add, value) }) ?? value else { continue }
            sum = next
            count += 1
        }
        guard let sum else { return nil }
        let isAverage = word == "average" || word == "avg"
        return (isAverage ? sum.applying(.divide, .number(count)) : sum).map(Item.value)
    }

    /// The text of a token as the keyword table has it.
    private static func text(of token: Token) -> String {
        switch token.kind {
        case .word(let word): word.lowercased()
        case .symbol(let symbol): symbol
        default: "\u{0}"
        }
    }

    mutating func evaluate() -> Value? {
        // An operator with nothing before it means nothing, but `-` and `+` can be signs.
        while case .binary(let operation) = peek, operation != .subtract, operation != .add { position += 1 }
        guard let value = parseConversion(), !failed else { return nil }
        // More values after the end of the calculation: the line is not clear, so it has no result.
        switch peek {
        case .value, .open, .function: return nil
        default: break
        }
        if case .number(let number, _) = value, !number.isFinite { return nil }
        return value
    }

    private var peek: Item? { position < items.count ? items[position] : nil }

    private mutating func fail() -> Value? {
        failed = true
        return nil
    }

    /// `255 in hex`, `5 km in miles`.
    private mutating func parseConversion() -> Value? {
        guard var value = parsePercentPhrase() else { return nil }
        while peek == .convert {
            switch position + 1 < items.count ? items[position + 1] : nil {
            case .style(let style):
                guard case .number(let number, _) = value else { return fail() }
                value = .number(number, style)
            case .unit(let unit):
                guard let converted = value.converted(to: unit) else { return fail() }
                value = converted
            default:
                return value
            }
            position += 2
        }
        return value
    }

    /// `20% of 10`.
    private mutating func parsePercentPhrase() -> Value? {
        guard let left = parseBinary(minimumPrecedence: 0) else { return nil }
        guard case .percentPhrase(let phrase) = peek else { return left }
        let start = position
        position += 1
        guard let right = parseBinary(minimumPrecedence: 0) else {
            position = start
            return left
        }
        return left.applying(phrase, right) ?? fail()
    }

    private mutating func parseBinary(minimumPrecedence: Int) -> Value? {
        guard var left = parseImplicit() else { return nil }
        while case .binary(let operation) = peek, operation != .power, operation.precedence >= minimumPrecedence {
            let start = position
            position += 1
            guard let right = parseBinary(minimumPrecedence: operation.precedence + 1) else {
                // An operator with nothing after it: ignore it and all that follows.
                position = start
                break
            }
            guard let result = left.applying(operation, right) else { return fail() }
            left = result
        }
        return left
    }

    /// `6 (3)`: a bracket directly after a value multiplies.
    /// `1 meter 20 cm`: a measurement directly after a measurement of the same type adds.
    private mutating func parseImplicit() -> Value? {
        guard var left = parseUnary() else { return nil }
        while true {
            if peek == .open {
                guard let right = parsePower() else { return nil }
                guard let result = left.applying(.multiply, right) else { return fail() }
                left = result
            } else if case .quantity(_, let unit) = left, case .value(.number) = peek {
                let start = position
                guard let right = parsePower(), case .quantity(_, let rightUnit) = right,
                      rightUnit.dimension == unit.dimension, let sum = left.applying(.add, right) else {
                    position = start
                    return left
                }
                left = sum
            } else {
                return left
            }
        }
    }

    private mutating func parseUnary() -> Value? {
        if peek == .binary(.subtract) {
            position += 1
            guard let value = parseUnary() else { return nil }
            return value.negated ?? fail()
        }
        if peek == .binary(.add) {
            position += 1
            return parseUnary()
        }
        return parsePower()
    }

    private mutating func parsePower() -> Value? {
        guard let base = parsePostfix() else { return nil }
        guard peek == .binary(.power) else { return base }
        let start = position
        position += 1
        guard let exponent = parseUnary() else {
            position = start
            return base
        }
        return base.applying(.power, exponent) ?? fail()
    }

    private mutating func parsePostfix() -> Value? {
        guard var value = parsePrimary() else { return nil }
        while true {
            switch peek {
            case .scale(let scale):
                guard let scaled = value.applying(.multiply, .number(scale)) else { return fail() }
                value = scaled
            case .percentSign:
                guard case .number(let number, _) = value else { return fail() }
                value = .percent(number)
            case .unit(let unit):
                // `$30 CAD`: a currency after a currency names the currency. It does not convert.
                switch value {
                case .number(let number, _): value = .quantity(number, unit)
                case .quantity(let number, let old) where old.dimension == .currency && unit.dimension == .currency:
                    value = .quantity(number, unit)
                default: return value
                }
            default:
                return value
            }
            position += 1
        }
    }

    /// `sqrt 16 + 2` is 6: without a bracket, a function uses only the value directly after it.
    private mutating func parseFunctionArgument() -> Value? {
        guard peek == .binary(.subtract) else { return parsePostfix() }
        position += 1
        guard let value = parsePostfix() else { return nil }
        return value.negated ?? fail()
    }

    private mutating func parsePrimary() -> Value? {
        switch peek {
        case .value(let value):
            position += 1
            return value
        case .open:
            position += 1
            guard let value = parseConversion() else { return nil }
            if peek == .close { position += 1 }
            return value
        case .function(let name):
            position += 1
            guard let first = parseFunctionArgument() else { return nil }
            var arguments = [first]
            // `root 3 (8)` and `log 2 (8)`: the number before the bracket is the degree or the base.
            if name == "root" || name == "log", peek == .open {
                guard let second = parsePrimary() else { return nil }
                arguments.append(second)
            }
            return Functions.apply(name, to: arguments) ?? fail()
        default:
            return nil
        }
    }
}
