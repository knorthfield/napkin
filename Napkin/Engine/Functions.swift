import Foundation

/// The functions that a note can use, such as `sqrt 16` and `round(3.45)`.
enum Functions {
    static let names: Set<String> = Set(plain.keys).union(keepingKind.keys).union(["root", "log", "fact"])

    private static let plain: [String: @Sendable (Double) -> Double] = [
        "sqrt": sqrt, "cbrt": cbrt, "ln": log,
        "sin": { withoutNoise(sin($0)) }, "cos": { withoutNoise(cos($0)) }, "tan": { withoutNoise(tan($0)) }, "arcsin": asin, "arccos": acos, "arctan": atan,
        "sinh": sinh, "cosh": cosh, "tanh": tanh,
    ]
    private static let takingAngle: Set<String> = ["sin", "cos", "tan"]
    /// These keep the percent sign or the unit of their argument: `round 3.4%` is 3%.
    private static let keepingKind: [String: @Sendable (Double) -> Double] = [
        "abs": { abs($0) },
        "round": { $0.rounded(.toNearestOrAwayFromZero) },
        "ceil": { $0.rounded(.up) },
        "floor": { $0.rounded(.down) },
    ]

    /// `sin pi` is 0, not 1.2e-16.
    private static func withoutNoise(_ number: Double) -> Double {
        (number * 1e15).rounded() / 1e15
    }

    static func apply(_ name: String, to arguments: [Value]) -> Value? {
        if let function = keepingKind[name], arguments.count == 1 {
            switch arguments[0] {
            case .number(let number, _): return .number(function(number))
            case .percent(let percent): return .percent(function(percent))
            case .quantity(let number, let unit): return .quantity(function(number), unit)
            }
        }
        let numbers = arguments.compactMap { argument -> Double? in
            switch argument {
            case .number(let number, _): number
            // `sin 30°`: an angle goes into the function in radians.
            case .quantity(let number, let unit) where unit.dimension == .angle && takingAngle.contains(name):
                number * unit.toBase
            default: nil
            }
        }
        guard numbers.count == arguments.count, let last = numbers.last else { return nil }
        switch name {
        case "root":
            return numbers.count == 2 ? .number(pow(last, 1 / numbers[0])) : nil
        case "log":
            return .number(numbers.count == 2 ? log(last) / log(numbers[0]) : log10(last))
        case "fact":
            guard last >= 0, last <= 170, last == last.rounded() else { return nil }
            return .number(tgamma(last + 1).rounded())
        case "arcsin", "arccos", "arctan":
            return .quantity(plain[name]!(last), UnitTable.radian)
        default:
            return plain[name].map { .number($0(last)) }
        }
    }
}
