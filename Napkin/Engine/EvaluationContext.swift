import Foundation

/// Everything the calculator gets from outside the note. Tests give fixed values.
struct EvaluationContext: Sendable {
    var decimalPlaces = 2
    /// The number of units of each currency in one euro, by currency code.
    var rates: [String: Double] = [:]
    var now = Date.now
    /// The time zone of `now`, `today` and clock times such as `2:30 pm`.
    var timeZone = TimeZone.current
    /// For the format of dates and times.
    var locale = Locale.current
}
