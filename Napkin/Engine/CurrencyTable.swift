/// Finds a currency from its code, name or symbol.
enum CurrencyTable {
    static let codeForSymbol: [String: String] = [
        "$": "USD", "€": "EUR", "£": "GBP", "¥": "JPY", "₹": "INR", "₽": "RUB", "₩": "KRW", "₪": "ILS",
        "₺": "TRY", "฿": "THB", "₱": "PHP",
    ]
    static let symbolForCode = Dictionary(uniqueKeysWithValues: codeForSymbol.map { ($1, $0) })

    /// The currencies that the European Central Bank publishes. They are known before the rates arrive.
    private static let codes: Set<String> = [
        "EUR", "USD", "JPY", "CZK", "DKK", "GBP", "HUF", "PLN", "RON", "SEK", "CHF", "ISK", "NOK", "TRY",
        "AUD", "BRL", "CAD", "CNY", "HKD", "IDR", "ILS", "INR", "KRW", "MXN", "MYR", "NZD", "PHP", "SGD",
        "THB", "ZAR",
    ]
    /// Names in lower case. The form with an `s` at the end is added automatically.
    private static let codeForName: [String: String] = Dictionary(uniqueKeysWithValues: [
        ("dollar", "USD"), ("euro", "EUR"), ("pound sterling", "GBP"), ("yen", "JPY"), ("yuan", "CNY"),
        ("franc", "CHF"), ("rupee", "INR"), ("rouble", "RUB"), ("ruble", "RUB"), ("won", "KRW"),
        ("krona", "SEK"), ("krone", "NOK"), ("zloty", "PLN"), ("peso", "MXN"), ("rand", "ZAR"),
        ("lira", "TRY"), ("shekel", "ILS"), ("baht", "THB"), ("forint", "HUF"), ("koruna", "CZK"),
        ("ringgit", "MYR"), ("rupiah", "IDR"),
    ].flatMap { [($0, $1), ($0 + "s", $1)] })

    /// `rates` gives the number of units of each currency in one euro. A currency with no rate still
    /// is a currency: amounts in it can be added, but not converted.
    static func currency(named text: String, rates: [String: Double]) -> UnitOfMeasure? {
        // Codes are `USD` or `usd`. The word `try` is not the Turkish lira.
        let isCode = text == text.uppercased() || (text == text.lowercased() && text != "try")
        let code = codeForSymbol[text] ?? codeForName[text.lowercased()] ?? text.uppercased()
        guard codes.contains(code) || rates[code] != nil, code == text.uppercased() ? isCode : true else { return nil }
        let toEuro = code == "EUR" ? 1 : rates[code].map { 1 / $0 } ?? .nan
        return UnitOfMeasure(symbol: code, dimension: .currency, toBase: toEuro)
    }
}
