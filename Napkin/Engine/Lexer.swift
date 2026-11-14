/// Divides one line into tokens. Characters that mean nothing to the calculator give no token.
struct Lexer {
    static let currencySymbols: Set<Character> = ["$", "€", "£", "¥", "₹", "₽", "₩", "₪", "₺", "฿", "₱"]
    private static let symbols: [Character: String] = [
        "+": "+", "-": "-", "−": "-", "–": "-", "*": "*", "×": "*", "/": "/", "÷": "/", "^": "^",
        "(": "(", ")": ")", "=": "=", "%": "%", "&": "&", "|": "|", ";": ";", "°": "°",
    ]

    private let text: Substring
    private var index: Substring.Index
    private var tokens: [Token] = []

    static func tokens(of text: Substring) -> [Token] {
        var lexer = Lexer(text: text, index: text.startIndex)
        lexer.run()
        return lexer.tokens
    }

    private func character(at offset: Int = 0) -> Character? {
        guard let position = text.index(index, offsetBy: offset, limitedBy: text.endIndex),
              position < text.endIndex else { return nil }
        return text[position]
    }

    private func isDigit(at offset: Int) -> Bool {
        character(at: offset).map { $0.isASCII && $0.isNumber } ?? false
    }

    private mutating func advance(_ count: Int = 1) {
        index = text.index(index, offsetBy: count)
    }

    private mutating func add(_ kind: Token.Kind, from start: Substring.Index) {
        tokens.append(Token(kind: kind, range: start..<index))
    }

    private mutating func run() {
        while let current = character() {
            let start = index
            if current.isASCII && current.isNumber || (current == "." && isDigit(at: 1)) {
                lexNumber()
            } else if current.isLetter {
                lexWord()
            } else if current == "°", let next = character(at: 1), next == "C" || next == "F",
                      !(character(at: 2)?.isLetter ?? false) {
                advance(2)
                add(.word("°\(next)"), from: start)
            } else if current == "\"" {
                advance()
                while let next = character(), next != "\"" { advance() }
                if character() != nil { advance() }
                add(.quoted, from: start)
            } else if current == "_" {
                while character() == "_" { advance() }
                add(.mark, from: start)
            } else if current == "`" || (current == "*" && character(at: 1) == "*")
                        || (current == "~" && character(at: 1) == "~") {
                advance(current == "`" ? 1 : 2)
                add(.mark, from: start)
            } else if (current == "<" || current == ">") && character(at: 1) == current {
                advance(2)
                add(.symbol("\(current)\(current)"), from: start)
            } else if let symbol = Self.symbols[current] {
                advance()
                add(.symbol(symbol), from: start)
            } else if Self.currencySymbols.contains(current) {
                advance()
                add(.currencySymbol(String(current)), from: start)
            } else {
                advance()
            }
        }
    }

    private mutating func lexWord() {
        let start = index
        while let current = character() {
            if current.isLetter || current.isNumber {
                advance()
            } else if current == "_" {
                // An underscore is part of the word only when more of the word follows it.
                var offset = 1
                while character(at: offset) == "_" { offset += 1 }
                guard let next = character(at: offset), next.isLetter || next.isNumber else { break }
                advance(offset)
            } else {
                break
            }
        }
        add(.word(String(text[start..<index])), from: start)
    }

    private mutating func lexNumber() {
        let start = index
        if character() == "0", let marker = character(at: 1)?.lowercased(),
           let radix = ["x": 16, "b": 2, "o": 8][marker],
           character(at: 2)?.hexDigitValue.map({ $0 < radix }) ?? false {
            advance(2)
            let digitsStart = index
            while character()?.hexDigitValue.map({ $0 < radix }) ?? false { advance() }
            if let value = UInt64(text[digitsStart..<index], radix: radix) {
                add(.number(Double(value)), from: start)
                return
            }
        }

        var digits = ""
        while isDigit(at: 0) {
            digits.append(character()!)
            advance()
        }
        if digits.count <= 2, character() == ":", isDigit(at: 1), isDigit(at: 2), !isDigit(at: 3) {
            let minute = Int(String([character(at: 1)!, character(at: 2)!]))!
            advance(3)
            add(.time(hour: Int(digits)!, minute: minute), from: start)
            return
        }
        // `5 300` and `5,300`: a space or a comma before exactly three digits is a thousands separator.
        if (1...3).contains(digits.count) {
            while character() == " " || character() == ",",
                  isDigit(at: 1), isDigit(at: 2), isDigit(at: 3), !isDigit(at: 4) {
                advance()
                for _ in 0..<3 {
                    digits.append(character()!)
                    advance()
                }
            }
        }
        if character() == ".", isDigit(at: 1) {
            digits.append(".")
            advance()
            while isDigit(at: 0) {
                digits.append(character()!)
                advance()
            }
        }
        if character()?.lowercased() == "e" {
            let signLength = (character(at: 1) == "+" || character(at: 1) == "-") ? 1 : 0
            if isDigit(at: 1 + signLength) {
                digits.append("e")
                if signLength == 1 { digits.append(character(at: 1)!) }
                advance(1 + signLength)
                while isDigit(at: 0) {
                    digits.append(character()!)
                    advance()
                }
            }
        }
        add(.number(Double(digits) ?? .nan), from: start)
    }
}
