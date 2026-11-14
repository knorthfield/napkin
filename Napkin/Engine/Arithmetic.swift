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

extension Value {
    var negated: Value? {
        switch self {
        case .number(let number, let style): .number(-number, style)
        }
    }

    /// The result of `self <operation> other`, or nil if the two values cannot be combined.
    func applying(_ operation: BinaryOperator, _ other: Value) -> Value? {
        switch (self, other) {
        case (.number(let left, _), .number(let right, _)):
            Self.calculate(operation, left, right).map { .number($0) }
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
