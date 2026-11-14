enum UnitDimension: Equatable, Sendable {
    case length, area, volume, mass, temperature, time, angle, data, currency
}

/// A unit of measurement. A value in this unit is `value * toBase + offset` in the base unit of
/// its dimension (metre, square metre, cubic metre, gram, kelvin, second, radian, bit, euro).
struct UnitOfMeasure: Sendable {
    /// The text after the number in a result.
    var symbol: String
    /// The text after a number that is not 1, if it is different: `inches`.
    var plural: String?
    var dimension: UnitDimension
    var toBase: Double
    /// Only temperature scales have an offset.
    var offset = 0.0
}

extension UnitOfMeasure: Equatable {
    /// A currency with no known rate has a `toBase` that is not a number, so do not compare `toBase`.
    static func == (left: UnitOfMeasure, right: UnitOfMeasure) -> Bool {
        left.symbol == right.symbol && left.dimension == right.dimension
    }
}
