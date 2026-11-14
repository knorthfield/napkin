import Testing
@testable import Napkin

struct CurrencyTests {
    /// One euro is 1.25 US dollars, 0.8 pounds, 1.5 Canadian dollars and 150 yen.
    private let context = EvaluationContext(rates: ["USD": 1.25, "GBP": 0.8, "CAD": 1.5, "JPY": 150])

    @Test(arguments: [
        ("$30", "$30.00"), ("$30 in Euro", "€24.00"), ("$30 in EUR", "€24.00"), ("30 USD in eur", "€24.00"),
        ("€10 in dollars", "$12.50"), ("£8 to CAD", "15.00 CAD"), ("10 euros in yen", "¥1,500.00"),
        ("EUR 30", "€30.00"), ("$30 CAD", "30.00 CAD"), ("$30 CAD + 5 USD - 7EUR", "€17.00"),
        ("$2k", "$2,000.00"), ("2M eur", "€2,000,000.00"), ("-$5", "-$5.00"),
        ("$10 - 40%", "$6.00"), ("20% of $10", "$2.00"), ("5% on $30", "$31.50"), ("6% off 40 EUR", "€37.60"),
        ("$50 as a % of $100", "50%"), ("5% of what is 6 EUR", "€120.00"),
        ("$20 in euro - 5% discount", "€15.20"), ("Price: $11 + $34.45", "$45.45"),
        ("$275 for the \"Model 227\"", "$275.00"), ("v = $20\nv times 7", "$140.00"), ("v = $20\nv + $10", "$30.00"),
        ("$10\n£8\nsum", "£14.40"), ("$10 / 4", "$2.50"), ("7 days * $60", "$420.00"), ("$60 * 7 days", "$420.00"),
        ("$90 / 3 hours", "$30.00"), ("$10 + 5", "$15.00"),
    ])
    func money(text: String, expected: String) {
        #expect(result(text, context: context) == expected)
    }

    @Test(arguments: [("$10 + $5", "$15.00"), ("$10 in EUR", nil), ("$10 + €5", nil), ("5 try", "5")])
    func withNoRates(text: String, expected: String?) {
        #expect(result(text) == expected)
    }
}
