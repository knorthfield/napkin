import Foundation

enum BinaryOperator: Equatable, Sendable {
    case add, subtract, multiply, divide, modulo, power
    case bitwiseAnd, bitwiseOr, bitwiseXor, shiftLeft, shiftRight

    /// A larger number binds its operands more tightly.
    var precedence: Int {
        switch self {
        case .bitwiseOr: 1
        case .bitwiseXor: 2
        case .bitwiseAnd: 3
        case .shiftLeft, .shiftRight: 4
        case .add, .subtract: 5
        case .multiply, .divide, .modulo: 6
        case .power: 7
        }
    }
}

enum PercentPhrase: Equatable, Sendable {
    case of, on, off, asPercentOf, asPercentOn, asPercentOff, ofWhatIs, onWhatIs, offWhatIs
}

extension Value {
    var negated: Value? {
        switch self {
        case .number(let number, let style): .number(-number, style)
        case .percent(let percent): .percent(-percent)
        }
    }

    /// The result of `self <operation> other`, or nil if the two values cannot be combined.
    func applying(_ operation: BinaryOperator, _ other: Value) -> Value? {
        switch (self, other) {
        case (.number(let left, _), .number(let right, _)):
            return Self.calculate(operation, left, right).map { .number($0) }
        case (.percent(let left), .percent(let right)):
            // 5% + 2% is 7%. 50% * 50% is 25%.
            switch operation {
            case .add, .subtract: return .percent(Self.calculate(operation, left, right)!)
            case .multiply: return .percent(left * right / 100)
            default: return nil
            }
        case (.percent(let left), .number(let right, _)):
            guard operation == .multiply || operation == .divide else { return nil }
            return .percent(Self.calculate(operation, left, right)!)
        case (_, .percent(let percent)):
            // 10 + 40% is 14. 10 - 40% is 6. 10 * 40% is 4. 10 / 40% is 25.
            switch operation {
            case .add: return applying(.multiply, .number(1 + percent / 100))
            case .subtract: return applying(.multiply, .number(1 - percent / 100))
            case .multiply, .divide: return applying(operation, .number(percent / 100))
            default: return nil
            }
        }
    }

    /// `20% of 10`, `50 as a % of 100`, `5% of what is 6`.
    func applying(_ phrase: PercentPhrase, _ other: Value) -> Value? {
        switch phrase {
        case .of, .on, .off, .ofWhatIs, .onWhatIs, .offWhatIs:
            guard case .percent(let percent) = self else { return nil }
            switch phrase {
            case .of: return other.applying(.multiply, .number(percent / 100))
            case .on: return other.applying(.multiply, .number(1 + percent / 100))
            case .off: return other.applying(.multiply, .number(1 - percent / 100))
            case .ofWhatIs: return other.applying(.divide, .number(percent / 100))
            case .onWhatIs: return other.applying(.divide, .number(1 + percent / 100))
            default: return other.applying(.divide, .number(1 - percent / 100))
            }
        case .asPercentOf, .asPercentOn, .asPercentOff:
            let part: Value? = switch phrase {
            case .asPercentOf: self
            case .asPercentOn: applying(.subtract, other)
            default: other.applying(.subtract, self)
            }
            guard case .number(let ratio, _) = part?.applying(.divide, other) else { return nil }
            return .percent(ratio * 100)
        }
    }

    static func calculate(_ operation: BinaryOperator, _ left: Double, _ right: Double) -> Double? {
        switch operation {
        case .add: return left + right
        case .subtract: return left - right
        case .multiply: return left * right
        case .divide: return left / right
        case .modulo: return left.truncatingRemainder(dividingBy: right)
        case .power: return pow(left, right)
        case .bitwiseAnd, .bitwiseOr, .bitwiseXor, .shiftLeft, .shiftRight:
            guard let left = Int64(exactly: left), let right = Int64(exactly: right) else { return nil }
            switch operation {
            case .bitwiseAnd: return Double(left & right)
            case .bitwiseOr: return Double(left | right)
            case .bitwiseXor: return Double(left ^ right)
            case .shiftLeft: return Double(left << right)
            default: return Double(left >> right)
            }
        }
    }
}
