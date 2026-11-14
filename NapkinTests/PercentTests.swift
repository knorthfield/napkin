import Testing
@testable import Napkin

struct PercentTests {
    @Test(arguments: [
        ("5%", "5%"), ("10 - 40%", "6"), ("10 + 40%", "14"), ("10 * 40%", "4"), ("10 / 40%", "25"),
        ("5% + 2%", "7%"), ("5% * 2", "10%"), ("50% * 50%", "25%"), ("-5%", "-5%"),
        ("v = 5%\n200 - v", "190"), ("200 - 10% - 10%", "162"),
    ])
    func operators(text: String, expected: String) {
        #expect(result(text) == expected)
    }

    @Test(arguments: [
        ("20% of 10", "2"), ("5% on 30", "31.5"), ("6% off 40", "37.6"),
        ("50 as a % of 100", "50%"), ("70 as a % on 20", "250%"), ("20 as a % off 70", "71.43%"),
        ("5% of what is 6", "120"), ("5% on what is 6", "5.71"), ("5% off what is 6", "6.32"),
        ("20% of (10 + 10)", "4"), ("v = 5%\nv of 200", "10"),
    ])
    func phrases(text: String, expected: String) {
        #expect(result(text) == expected)
    }

    @Test(arguments: ["5 of 10", "5% + 10", "2 ^ 5%"])
    func percentagesWithNoMeaning(text: String) {
        #expect(result(text) == nil)
    }
}
