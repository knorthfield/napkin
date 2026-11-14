import Foundation

/// Calculates the value of one line. It first gives each token a meaning (words that mean nothing are
/// ignored), then calculates while it reads the meanings, operators with a higher precedence first.
struct LineEvaluator {
    private enum Item: Equatable {
        case value(Value)
        case binary(BinaryOperator)
        case open, close
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
    ]
    private static let longestPhrase = 4

    private var items: [Item] = []
    private var position = 0
    /// True when the line has a meaning but no value, for example a division of text by a number.
    private var failed = false

    init(tokens: [Token]) {
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
            if let keyword {
                items.append(keyword)
                index += length
            } else {
                if case .number(let number) = tokens[index].kind { items.append(.value(.number(number))) }
                index += 1
            }
        }
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
        guard let value = parseBinary(minimumPrecedence: 0), !failed else { return nil }
        // More values after the end of the calculation: the line is not clear, so it has no result.
        switch peek {
        case .value, .open: return nil
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
    private mutating func parseImplicit() -> Value? {
        guard var left = parseUnary() else { return nil }
        while peek == .open {
            guard let right = parsePower() else { return nil }
            guard let result = left.applying(.multiply, right) else { return fail() }
            left = result
        }
        return left
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
        guard let base = parsePrimary() else { return nil }
        guard peek == .binary(.power) else { return base }
        let start = position
        position += 1
        guard let exponent = parseUnary() else {
            position = start
            return base
        }
        return base.applying(.power, exponent) ?? fail()
    }

    private mutating func parsePrimary() -> Value? {
        switch peek {
        case .value(let value):
            position += 1
            return value
        case .open:
            position += 1
            guard let value = parseBinary(minimumPrecedence: 0) else { return nil }
            if peek == .close { position += 1 }
            return value
        default:
            return nil
        }
    }
}
