/// How a plain number is shown.
import Foundation

enum NumberStyle: Equatable, Sendable {
    case decimal, hexadecimal, binary, octal, scientific
}

/// The parts of a date that a result shows.
enum DateParts: Equatable, Sendable {
    case date, time, dateAndTime
}

/// The result of a line, or of a part of a line.
enum Value: Equatable, Sendable {
    case number(Double, NumberStyle = .decimal)
    /// `5%` is `.percent(5)`.
    case percent(Double)
    /// A number with a unit of measurement or a currency.
    case quantity(Double, UnitOfMeasure)
    /// A moment, shown as the date or the clock time in a time zone.
    case date(Date, TimeZone, DateParts)

    var isDate: Bool {
        if case .date = self { true } else { false }
    }

    /// This value in a different unit. A plain number gets the unit.
    func converted(to unit: UnitOfMeasure) -> Value? {
        switch self {
        case .number(let number, _):
            return .quantity(number, unit)
        case .quantity(let number, let old):
            guard old.dimension == unit.dimension else { return nil }
            if old == unit { return self }
            let converted = (number * old.toBase + old.offset - unit.offset) / unit.toBase
            return converted.isNaN ? nil : .quantity(converted, unit)
        case .percent, .date:
            return nil
        }
    }
}
