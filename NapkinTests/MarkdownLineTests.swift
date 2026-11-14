import Testing
@testable import Napkin

struct MarkdownLineTests {
    @Test(arguments: [
        "# 2 + 2", "###### 2 + 2", "// 2 + 2", "> 2 + 2", "| 2 | 3 |", "---", "***", "_ _ _", "```", "  // 5",
    ])
    func textLinesHaveNoResult(line: String) {
        #expect(result(line) == nil)
    }

    @Test func aFencedCodeBlockIsNotCalculated() {
        #expect(Calculator.evaluate("```\n1 + 1\n```\n1 + 1").map(\.display) == [nil, nil, nil, "2"])
    }

    @Test(arguments: [
        ("- 5", "5"), ("-5", "-5"), ("* 3 * 2", "6"), ("+ 4", "4"), ("1. 500", "500"), ("2) 3 + 1", "4"),
        ("  - 2 + 2", "4"), ("- [ ] 10 * 2", "20"), ("- [x] 10 * 2", "20"), ("- milk: 3 * 2", "6"),
    ])
    func listItemsAreCalculated(line: String, expected: String) {
        #expect(result(line) == expected)
    }

    @Test(arguments: [
        ("**5** + 1", "6"), ("__5__ + 1", "6"), ("~~5~~ + 1", "6"), ("`5 * 2`", "10"), ("_5_ + 1", "6"),
        ("**Total:** 5 + 1", "6"),
    ])
    func inlineMarksAreIgnored(line: String, expected: String) {
        #expect(result(line) == expected)
    }

    @Test(arguments: [
        ("Price: 11 + 34.45", "45.45"), ("Q1 2026: 500", "500"), ("275 for the \"Model 227\"", "275"),
        ("20 - 5 discount", "15"), ("Rent:", nil), ("#5 + 1", "6"),
    ])
    func labelsAndComments(line: String, expected: String?) {
        #expect(result(line) == expected)
    }
}
