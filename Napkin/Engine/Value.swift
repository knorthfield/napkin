/// How a plain number is shown.
enum NumberStyle: Equatable, Sendable {
    case decimal, hexadecimal, binary, octal, scientific
}

/// The result of a line, or of a part of a line.
enum Value: Equatable, Sendable {
    case number(Double, NumberStyle = .decimal)
}
