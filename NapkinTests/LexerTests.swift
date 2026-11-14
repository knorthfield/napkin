import Testing
@testable import Napkin

struct LexerTests {
    private func kinds(_ line: String) -> [Token.Kind] {
        Lexer.tokens(of: line[...]).map(\.kind)
    }

    @Test func numbersWordsAndSymbols() {
        #expect(kinds("12.5 plus (3*x)") == [
            .number(12.5), .word("plus"), .symbol("("), .number(3), .symbol("*"), .word("x"), .symbol(")"),
        ])
    }

    @Test(arguments: [
        ("5 300", 5300.0), ("1,234,567.5", 1_234_567.5), (".5", 0.5), ("2e3", 2000.0), ("1.5e-3", 0.0015),
        ("0xFF", 255.0), ("0b110", 6.0), ("0o17", 15.0),
    ])
    func numberForms(line: String, value: Double) {
        #expect(kinds(line) == [.number(value)])
    }

    @Test func aSpaceBeforeFewerThanThreeDigitsIsNotAThousandsSeparator() {
        #expect(kinds("1 meter 20 cm") == [.number(1), .word("meter"), .number(20), .word("cm")])
        #expect(kinds("2 (8)") == [.number(2), .symbol("("), .number(8), .symbol(")")])
    }

    @Test func aUnitGluedToANumberIsASeparateWord() {
        #expect(kinds("7EUR") == [.number(7), .word("EUR")])
        #expect(kinds("2em") == [.number(2), .word("em")])
        #expect(kinds("$5k") == [.currencySymbol("$"), .number(5), .word("k")])
    }

    @Test func clockTimesAndDegrees() {
        #expect(kinds("2:30 pm") == [.time(hour: 2, minute: 30), .word("pm")])
        #expect(kinds("45° 20 °C") == [.number(45), .symbol("°"), .number(20), .word("°C")])
    }

    @Test func shiftsAndOtherSpellingsOfOperators() {
        #expect(kinds("1 << 2 × 3 ÷ 4") == [
            .number(1), .symbol("<<"), .number(2), .symbol("*"), .number(3), .symbol("/"), .number(4),
        ])
    }

    @Test func quotedCommentsAndMarkdownMarks() {
        #expect(kinds("5 \"Model 227\"") == [.number(5), .quoted])
        #expect(kinds("**5** _tax_rate_ `2`") == [
            .mark, .number(5), .mark, .mark, .word("tax_rate"), .mark, .mark, .number(2), .mark,
        ])
    }

    @Test func tokensKeepTheirPlaceInTheLine() {
        let line = "ab + 12"
        let tokens = Lexer.tokens(of: line[...])
        #expect(tokens.map { String(line[$0.range]) } == ["ab", "+", "12"])
    }
}
