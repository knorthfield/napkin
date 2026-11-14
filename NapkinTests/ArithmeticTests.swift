import Testing
@testable import Napkin

/// The text that the results column shows for the last line, or nil if that line has no result.
func result(_ text: String, context: EvaluationContext = EvaluationContext()) -> String? {
    Calculator.evaluate(text, context: context).last?.display
}

struct ArithmeticTests {
    @Test(arguments: [
        ("1 + 2", "3"), ("7 - 10", "-3"), ("2 + 3 * 4", "14"), ("(2 + 3) * 4", "20"), ("10 / 4", "2.5"),
        ("2 ^ 3 ^ 2", "512"), ("-2 ^ 2", "-4"), ("2 ^ -1", "0.5"), ("-3 + 5", "2"), ("2 * -3", "-6"),
        ("0.1 + 0.2", "0.3"), ("10 / 3", "3.33"), ("1 / 800", "0.0013"), ("1234567.891", "1,234,567.89"),
        ("2 ^ 70", "1.18e21"), ("17 mod 5", "2"),
    ])
    func symbols(line: String, expected: String) {
        #expect(result(line) == expected)
    }

    @Test(arguments: [
        ("8 times 9", "72"), ("2 plus 3", "5"), ("2 and 3 with 4", "9"), ("10 minus 4", "6"),
        ("10 without 4", "6"), ("3 multiplied by 4", "12"), ("3 mul 4", "12"), ("3 x 4", "12"),
        ("12 divide by 4", "3"), ("12 divided by 4", "3"), ("12 divide 4", "3"),
    ])
    func words(line: String, expected: String) {
        #expect(result(line) == expected)
    }

    @Test(arguments: [
        ("6 & 3", "2"), ("6 | 3", "7"), ("6 xor 3", "5"), ("1 << 4", "16"), ("256 >> 4", "16"),
        ("1 | 2 & 3", "3"),
    ])
    func bitwise(line: String, expected: String) {
        #expect(result(line) == expected)
    }

    @Test(arguments: [("6 (3)", "18"), ("2 (3) (4)", "24"), ("(1 + 1)(3)", "6")])
    func aBracketAfterAValueMultiplies(line: String, expected: String) {
        #expect(result(line) == expected)
    }

    @Test(arguments: [("2 + 3 apples", "5"), ("eggs 12 times 2", "24"), ("5 +", "5"), ("(2 + 3", "5")])
    func wordsWithNoMeaningAreIgnored(line: String, expected: String) {
        #expect(result(line) == expected)
    }

    @Test(arguments: ["", "hello", "3 apples 4 pears", "1 / 0", "1.5 & 2"])
    func linesWithNoResult(line: String) {
        #expect(result(line) == nil)
    }
}
