import Testing
@testable import Napkin

struct FunctionTests {
    @Test(arguments: [
        ("sqrt 16", "4"), ("sqrt(16) + 2", "6"), ("sqrt 16 + 2", "6"), ("cbrt 8", "2"), ("root 2 (8)", "2.83"),
        ("root 3 (27)", "3"), ("abs(-4)", "4"), ("abs -4", "4"), ("log 2 (8)", "3"), ("log(100)", "2"),
        ("log 1000", "3"), ("ln e", "1"), ("fact 5", "120"), ("fact 0", "1"),
        ("round 3.45", "3"), ("round 3.5", "4"), ("ceil 3.76", "4"), ("floor 2.56", "2"), ("round 3.4%", "3%"),
        ("sin 0", "0"), ("sin pi", "0"), ("cos pi", "-1"), ("tan(pi / 4)", "1"), ("arcsin 1", "1.57 rad"), ("arccos 1", "0 rad"),
        ("arctan 1", "0.79 rad"), ("sin 30°", "0.5"), ("cos 60 degrees", "0.5"), ("sin 90 deg", "1"),
        ("arcsin 1 in degrees", "90°"), ("round(2.6 km)", "3 km"), ("sinh 0", "0"), ("cosh 0", "1"), ("tanh 0", "0"),
        ("2 * sqrt(9) ^ 2", "18"), ("SQRT 16", "4"),
    ])
    func functions(text: String, expected: String) {
        #expect(result(text) == expected)
    }

    @Test(arguments: ["sqrt", "fact 2.5", "fact -1", "sqrt = 4\nsqrt"])
    func functionsWithNoResult(text: String) {
        #expect(result(text) != "4" && result(text) != "2")
    }
}
