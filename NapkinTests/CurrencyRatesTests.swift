import Foundation
import Testing
@testable import Napkin

@MainActor
struct CurrencyRatesTests {
    private let response = Data("""
        [{"date":"2026-11-13","base":"EUR","quote":"AUD","rate":1.6288},
         {"date":"2026-11-13","base":"EUR","quote":"USD","rate":1.1612},
         {"date":"2026-11-13","base":"EUR","quote":"EUR","rate":1.0}]
        """.utf8)

    @Test func decodesTheResponse() throws {
        let rates = try CurrencyRates.decode(response)
        #expect(rates.date == "2026-11-13")
        #expect(rates.perEuro == ["AUD": 1.6288, "USD": 1.1612, "EUR": 1])
    }

    @Test func aResponseWithNoRatesIsAnError() {
        #expect(throws: (any Error).self) { try CurrencyRates.decode(Data("[]".utf8)) }
        #expect(throws: (any Error).self) { try CurrencyRates.decode(Data("not JSON".utf8)) }
    }

    @Test func theSavedRatesAreReadWhenTheAppOpens() throws {
        let file = FileManager.default.temporaryDirectory.appending(path: "NapkinRates-\(UUID().uuidString).json")
        #expect(CurrencyRates(cacheFile: file).perEuro.isEmpty)
        try response.write(to: file)
        let rates = CurrencyRates(cacheFile: file)
        #expect(rates.date == "2026-11-13")
        #expect(result("116.12 USD in EUR", context: EvaluationContext(rates: rates.perEuro)) == "€100.00")
    }
}
