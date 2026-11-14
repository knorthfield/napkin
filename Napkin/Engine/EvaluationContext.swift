import Foundation

/// Everything the calculator gets from outside the note. Tests give fixed values.
struct EvaluationContext: Sendable {
    var decimalPlaces = 2
    /// The number of units of each currency in one euro, by currency code.
    var rates: [String: Double] = [:]
}
