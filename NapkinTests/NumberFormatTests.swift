import Testing
@testable import Napkin

struct NumberFormatTests {
    @Test(arguments: [
        ("0xFF", "255"), ("0b110111011", "443"), ("0o17 + 1", "16"), ("5 300", "5,300"),
        ("255 in hex", "0xFF"), ("0o1435343 in hex", "0x63AE3"), ("5 into bin", "0b101"),
        ("8 as oct", "0o10"), ("-255 to hex", "-0xFF"), ("5 300 in sci", "5.3e3"),
        ("0.00012 in scientific", "1.2e-4"), ("(255 in hex) + 1", "256"),
    ])
    func radixAndScientific(line: String, expected: String) {
        #expect(result(line) == expected)
    }

    @Test(arguments: [
        ("2k", "2,000"), ("2 k", "2,000"), ("1.5M", "1,500,000"), ("3 thousand", "3,000"),
        ("2 million", "2,000,000"), ("1 billion", "1,000,000,000"), ("2k + 500", "2,500"),
        ("5 in stock", "5"),
    ])
    func scales(line: String, expected: String) {
        #expect(result(line) == expected)
    }
}
