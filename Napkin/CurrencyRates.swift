import Foundation
import Observation

/// The exchange rates of the European Central Bank, from frankfurter.dev (free, no key).
/// The last rates stay in a file, so that currencies also convert when there is no network.
@MainActor @Observable
final class CurrencyRates {
    static let defaultCacheFile = URL.applicationSupportDirectory.appending(path: "Napkin/rates.json")
    private static let source = URL(string: "https://api.frankfurter.dev/v2/rates?base=EUR&providers=ECB")!
    private static let longestAge: TimeInterval = 12 * 60 * 60

    /// The number of units of each currency in one euro, by currency code.
    private(set) var perEuro: [String: Double] = [:]
    /// The day of the rates, such as `2026-11-13`.
    private(set) var date: String?

    @ObservationIgnored private let cacheFile: URL

    init(cacheFile: URL = CurrencyRates.defaultCacheFile) {
        self.cacheFile = cacheFile
        if let data = try? Data(contentsOf: cacheFile), let rates = try? Self.decode(data) {
            (date, perEuro) = rates
        }
    }

    /// Gets new rates if the saved rates are more than 12 hours old. With no network, the saved rates stay.
    func refreshIfOld() async {
        let saved = try? FileManager.default.attributesOfItem(atPath: cacheFile.path)[.modificationDate] as? Date
        if let saved, !perEuro.isEmpty, Date.now.timeIntervalSince(saved) < Self.longestAge { return }
        guard let (data, _) = try? await URLSession.shared.data(from: Self.source),
              let rates = try? Self.decode(data) else { return }
        (date, perEuro) = rates
        try? FileManager.default.createDirectory(at: cacheFile.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? data.write(to: cacheFile, options: .atomic)
    }

    /// The response is a list such as `[{"date":"2026-11-13","base":"EUR","quote":"AUD","rate":1.6288}]`.
    nonisolated static func decode(_ data: Data) throws -> (date: String, perEuro: [String: Double]) {
        struct Rate: Decodable {
            var date: String
            var quote: String
            var rate: Double
        }
        let rates = try JSONDecoder().decode([Rate].self, from: data)
        guard let date = rates.map(\.date).max() else { throw CocoaError(.coderValueNotFound) }
        return (date, Dictionary(rates.map { ($0.quote, $0.rate) }, uniquingKeysWith: { first, _ in first }))
    }
}
