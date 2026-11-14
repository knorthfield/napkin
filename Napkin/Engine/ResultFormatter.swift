import Foundation

/// Makes the text that the results column shows for a value.
enum ResultFormatter {
    static func string(for value: Value, context: EvaluationContext) -> String {
        switch value {
        case .number(let number, let style):
            switch style {
            case .decimal: return decimalString(number, decimalPlaces: context.decimalPlaces)
            case .scientific: return scientificString(number, decimalPlaces: context.decimalPlaces)
            case .hexadecimal: return integerString(number, radix: 16, prefix: "0x")
            case .binary: return integerString(number, radix: 2, prefix: "0b")
            case .octal: return integerString(number, radix: 8, prefix: "0o")
            }
        case .percent(let percent):
            return decimalString(percent, decimalPlaces: context.decimalPlaces) + "%"
        case .date(let date, let zone, let parts):
            let style = Date.FormatStyle(locale: context.locale, timeZone: zone)
            switch parts {
            case .date: return date.formatted(style.weekday(.abbreviated).day().month(.abbreviated).year())
            case .time: return date.formatted(style.hour().minute())
            case .dateAndTime: return date.formatted(style.day().month(.abbreviated).year().hour().minute())
            }
        case .quantity(let number, let unit) where unit.dimension == .currency:
            // Money always has two decimal places: $1,234.50, 1,234.50 CAD.
            let amount = abs(number).formatted(
                .number.precision(.fractionLength(2)).rounded(rule: .toNearestOrAwayFromZero)
                    .locale(Locale(identifier: "en_GB"))
            )
            let sign = number < 0 && amount != "0.00" ? "-" : ""
            if let symbol = CurrencyTable.symbolForCode[unit.symbol] { return sign + symbol + amount }
            return "\(sign)\(amount) \(unit.symbol)"
        case .quantity(let number, let unit):
            return decimalString(number, decimalPlaces: context.decimalPlaces)
                + (unit.symbol == "°" ? "" : " ")
                + (abs(number) == 1 ? unit.symbol : unit.plural ?? unit.symbol)
        }
    }

    static func decimalString(_ number: Double, decimalPlaces: Int) -> String {
        let magnitude = abs(number)
        guard magnitude > 0 else { return "0" }
        if magnitude >= 1e15 || magnitude < 1e-9 {
            return scientificString(number, decimalPlaces: decimalPlaces)
        }
        // A number less than 1 keeps its decimal places after the zeros: 0.001234 shows 0.0012.
        let leadingZeros = magnitude < 1 ? Int((-log10(magnitude)).rounded(.up)) - 1 : 0
        // No more than 12 decimal places: they hide binary floating-point noise.
        let fractionDigits = min(decimalPlaces + leadingZeros, 12)
        let text = number.formatted(
            .number
                .precision(.fractionLength(0...fractionDigits))
                .rounded(rule: .toNearestOrAwayFromZero)
                .locale(Locale(identifier: "en_GB"))
        )
        return text == "-0" ? "0" : text
    }

    private static func scientificString(_ number: Double, decimalPlaces: Int) -> String {
        guard number != 0 else { return "0" }
        var exponent = Int(log10(abs(number)).rounded(.down))
        var mantissa = decimalString(number / pow(10, Double(exponent)), decimalPlaces: decimalPlaces)
        if mantissa == "10" || mantissa == "-10" {
            mantissa = mantissa.replacingOccurrences(of: "10", with: "1")
            exponent += 1
        }
        return "\(mantissa)e\(exponent)"
    }

    private static func integerString(_ number: Double, radix: Int, prefix: String) -> String {
        guard let integer = Int64(exactly: number.rounded(.towardZero)) else {
            return decimalString(number, decimalPlaces: 0)
        }
        return (integer < 0 ? "-" : "") + prefix + String(integer.magnitude, radix: radix, uppercase: true)
    }
}
