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
        case zone(TimeZone)
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
            || Functions.names.contains(word) || dateWords.contains(word)
    }

    private static let constants: [String: Double] = ["pi": .pi, "π": .pi, "e": M_E]
    private static let lineReferences: Set<String> = ["prev", "sum", "total", "average", "avg"]
    private static let dateWords: Set<String> = ["now", "time", "today", "tomorrow", "yesterday"]

    private let state: DocumentState
    private let context: EvaluationContext
    /// True when the line uses `sum`, `total`, `average` or `avg`.
    private(set) var usesBlock = false
    /// The meaning of each token for syntax colours, or nil for a token that means nothing.
    private(set) var roles: [TokenRole?]
    private var items: [Item] = []
    private var position = 0
    /// True when the line has a meaning but no value, for example a division of text by a number.
    private var failed = false

    init(tokens: [Token], state: DocumentState, context: EvaluationContext) {
        self.state = state
        self.context = context
        roles = tokens.map { token in
            switch token.kind {
            case .quoted: .comment
            case .mark: .mark
            default: nil
            }
        }
        let texts = tokens.map(Self.text)
        var index = 0
        while index < tokens.count {
            if let (time, length) = clockTime(at: index, in: tokens) {
                roles.replaceSubrange(index..<index + length, with: repeatElement(.number, count: length))
                items.append(.value(time))
                index += length
                continue
            }
            var length = min(Self.longestPhrase, tokens.count - index)
            var keyword: Item?
            while length > 0 {
                keyword = Self.keywords[texts[index..<index + length].joined(separator: " ")]
                if keyword != nil { break }
                length -= 1
            }
            // A note can use `x` as a variable. Then it is not the multiplication sign.
            if case .word(let word) = tokens[index].kind, state.variables[word] != nil { keyword = nil }
            var role: TokenRole?
            if let keyword {
                items.append(keyword)
                switch keyword {
                case .open, .close: role = nil
                case .unit: role = .unit
                default: role = .keyword
                }
            } else if let (unit, unitLength) = unit(at: index, in: tokens) {
                items.append(.unit(unit))
                (role, length) = (.unit, unitLength)
            } else if let (zone, zoneLength) = zone(at: index, in: tokens) {
                items.append(.zone(zone))
                (role, length) = (.unit, zoneLength)
            } else {
                length = 1
                if let item = meaning(of: tokens[index], after: index > 0 ? tokens[index - 1] : nil) {
                    items.append(item)
                    switch (item, tokens[index].kind) {
                    case (.value, .number): role = .number
                    case (.value, .word(let word)): role = state.variables[word] != nil ? .variable : .function
                    case (.function, _): role = .function
                    default: role = .unit
                    }
                }
            }
            if let role { roles.replaceSubrange(index..<index + length, with: repeatElement(role, count: length)) }
            index += length
        }
    }

    /// A unit is one to three words: `km`, `sq ft`, `square nautical miles`. A word is a unit only after
    /// a value or after `in`, `into`, `as` or `to`, so that `are` and `hand` in a sentence mean nothing.
    private func unit(at index: Int, in tokens: [Token]) -> (UnitOfMeasure, Int)? {
        if case .currencySymbol(let symbol) = tokens[index].kind {
            return CurrencyTable.currency(named: symbol, rates: context.rates).map { ($0, 1) }
        }
        switch items.last {
        case .value, .scale, .close, .convert:
            break
        default:
            // `EUR 30`: a currency code can be before its number.
            guard case .word(let word) = tokens[index].kind, word == word.uppercased(), index + 1 < tokens.count,
                  case .number = tokens[index + 1].kind, state.variables[word] == nil,
                  let currency = CurrencyTable.currency(named: word, rates: context.rates) else { return nil }
            return (currency, 1)
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
            if let unit = screenUnit(named: name) ?? UnitTable.unit(named: name)
                ?? CurrencyTable.currency(named: name, rates: context.rates) {
                return (unit, length)
            }
        }
        return nil
    }

    /// `2:30`, `2:30 pm` and `5 pm` are clock times of today.
    private func clockTime(at index: Int, in tokens: [Token]) -> (Value, Int)? {
        var half: String?
        if index + 1 < tokens.count, case .word(let word) = tokens[index + 1].kind,
           ["am", "pm"].contains(word.lowercased()), state.variables[word] == nil {
            half = word.lowercased()
        }
        var hour: Int
        var minute = 0
        switch tokens[index].kind {
        case .time(let tokenHour, let tokenMinute): (hour, minute) = (tokenHour, tokenMinute)
        case .number(let number) where half != nil && (1...12).contains(number) && number == number.rounded(): hour = Int(number)
        default: return nil
        }
        if half != nil, hour == 12 { hour = 0 }
        if half == "pm" { hour += 12 }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = context.timeZone
        guard hour < 24, minute < 60,
              let date = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: context.now) else { return nil }
        return (.date(date, context.timeZone, .time), half == nil ? 1 : 2)
    }

    /// A time zone is one to three words: `PST`, `Madrid`, `New York`, `Ho Chi Minh`. A word is a time zone
    /// only next to a time (`2:30 pm HKT`, `New York time`) or after `in`, `into`, `as` or `to`.
    private func zone(at index: Int, in tokens: [Token]) -> (TimeZone, Int)? {
        var words: [String] = []
        for token in tokens[index...].prefix(3) {
            guard case .word(let word) = token.kind else { break }
            words.append(word)
        }
        guard let first = words.first, state.variables[first] == nil else { return nil }
        var isAfterTime = items.last == .convert
        if case .value(.date) = items.last { isAfterTime = true }
        for length in stride(from: words.count, through: 1, by: -1) {
            guard let zone = TimeZoneTable.zone(named: words[..<length].joined(separator: " ")) else { continue }
            var isBeforeTime = false
            if index + length < tokens.count, case .word(let next) = tokens[index + length].kind {
                isBeforeTime = next.lowercased() == "time" || next.lowercased() == "now"
            }
            if isAfterTime || isBeforeTime { return (zone, length) }
        }
        return nil
    }

    /// The moment that `now`, `time`, `today`, `tomorrow` or `yesterday` means.
    private func date(for word: String) -> Value? {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = context.timeZone
        let today = calendar.startOfDay(for: context.now)
        switch word {
        case "now": return .date(context.now, context.timeZone, .dateAndTime)
        case "time": return .date(context.now, context.timeZone, .time)
        case "today": return .date(today, context.timeZone, .date)
        case "tomorrow": return calendar.date(byAdding: .day, value: 1, to: today).map { .date($0, context.timeZone, .date) }
        case "yesterday": return calendar.date(byAdding: .day, value: -1, to: today).map { .date($0, context.timeZone, .date) }
        default: return nil
        }
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
            if let date = date(for: word.lowercased()) { return .value(date) }
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

    /// `255 in hex`, `5 km in miles`. A calculation can continue after it: `$20 in EUR - 5%`.
    private mutating func parseConversion() -> Value? {
        guard var value = parsePercentPhrase() else { return nil }
        while true {
            if case .binary = peek {
                guard let continued = parseBinary(minimumPrecedence: 0, startingWith: value) else { return nil }
                if continued == value { return value }
                value = continued
            }
            guard peek == .convert else { return value }
            switch position + 1 < items.count ? items[position + 1] : nil {
            case .style(let style):
                guard case .number(let number, _) = value else { return fail() }
                value = .number(number, style)
            case .unit(let unit):
                guard let converted = value.converted(to: unit) else { return fail() }
                value = converted
            case .zone(let zone):
                // `time in Madrid`: the same moment, on the clocks of a different place.
                guard case .date(let date, _, let parts) = value else { return fail() }
                value = .date(date, zone, parts)
            case _ where value.isDate:
                // `time in Atlantis`: do not show the local time for a place that is not known.
                return fail()
            default:
                return value
            }
            position += 2
        }
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

    private mutating func parseBinary(minimumPrecedence: Int, startingWith first: Value? = nil) -> Value? {
        guard var left = first ?? parseImplicit() else { return nil }
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
            case .zone(let zone):
                // `2:30 pm HKT`: the clock time is a time in Hong Kong.
                guard case .date(let date, let old, let parts) = value else { return value }
                var calendar = Calendar(identifier: .gregorian)
                calendar.timeZone = old
                let clock = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
                calendar.timeZone = zone
                guard let moved = calendar.date(from: clock) else { return fail() }
                value = .date(moved, zone, parts)
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
        case .unit(let unit) where unit.dimension == .currency:
            // `$30`, `EUR 30`.
            guard position + 1 < items.count, case .value(.number(let number, _)) = items[position + 1] else { return nil }
            position += 2
            return .quantity(number, unit)
        case .open:
            position += 1
            guard let value = parseConversion() else { return nil }
            if peek == .close { position += 1 }
            return value
        case .zone(let zone):
            // `New York time`.
            guard position + 1 < items.count, case .value(.date(let date, _, let parts)) = items[position + 1] else { return nil }
            position += 2
            return .date(date, zone, parts)
        case .function(let name):
            position += 1
            guard let first = parseFunctionArgument() else { return nil }
            if name == "fromunix" {
                guard case .number(let seconds, _) = first else { return fail() }
                return .date(Date(timeIntervalSince1970: seconds), context.timeZone, .dateAndTime)
            }
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
