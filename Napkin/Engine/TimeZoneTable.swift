import Foundation

/// Finds a time zone from a city (`Madrid`, `New York`) or an abbreviation (`PST`, `HKT`).
/// The cities are those in the names of the time zones of the system, such as `Europe/Madrid`.
enum TimeZoneTable {
    private static let zones: [String: TimeZone] = {
        var zones: [String: TimeZone] = ["utc": .gmt, "gmt": .gmt]
        for identifier in TimeZone.knownTimeZoneIdentifiers {
            guard let zone = TimeZone(identifier: identifier), let city = identifier.split(separator: "/").last else { continue }
            zones[city.replacingOccurrences(of: "_", with: " ").lowercased()] = zone
        }
        for (abbreviation, identifier) in TimeZone.abbreviationDictionary {
            if let zone = TimeZone(identifier: identifier) { zones[abbreviation.lowercased()] = zone }
        }
        return zones
    }()

    static func zone(named name: String) -> TimeZone? {
        zones[name.lowercased()]
    }
}
