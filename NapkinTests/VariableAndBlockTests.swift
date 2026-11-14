import Testing
@testable import Napkin

struct VariableAndBlockTests {
    @Test(arguments: [
        ("v = 20\nv times 7", "140"), ("v = 20\nv2 = 5\nv + v2", "25"), ("tax_rate = 0.2\n100 * tax_rate", "20"),
        ("x = 4\n3 x 2\nx + 1", "5"), ("a = 1\na = a + 1\na", "2"), ("v = 3", "3"),
        ("V = 1\nv = 2\nV", "1"),
    ])
    func variables(text: String, expected: String) {
        #expect(result(text) == expected)
    }

    @Test(arguments: [("plus = 5\n1 plus 2", "3"), ("pi = 3\npi * 2", "6.28"), ("sum = 3\nsum", nil)])
    func aKeywordCannotBeAVariable(text: String, expected: String?) {
        #expect(result(text) == expected)
    }

    @Test(arguments: [("pi", "3.14"), ("2 * Pi", "6.28"), ("e", "2.72"), ("E ^ 2", "7.39")])
    func constants(text: String, expected: String) {
        #expect(result(text) == expected)
    }

    @Test(arguments: [
        ("10\nprev * 2", "20"), ("10\nsome text\nprev + 1", "11"),
        ("1\n2\n3\nsum", "6"), ("1\n2\n3\ntotal", "6"), ("2\n4\naverage", "3"), ("2\n4\navg", "3"),
        ("100\n\n1\n2\nsum", "3"), ("1\n2\ntotal\ntotal * 2", "6"), ("1\n# heading\n2\nsum", "3"),
    ])
    func lineReferences(text: String, expected: String) {
        #expect(result(text) == expected)
    }

    @Test func eachLineHasItsOwnResult() {
        #expect(Calculator.evaluate("1 + 1\n\nhello\n2 * 3").map(\.display) == ["2", nil, nil, "6"])
    }
}
