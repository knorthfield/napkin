/// What a token means in its line, for syntax colours.
enum TokenRole: Equatable, Sendable {
    case number, keyword, unit, variable, function, comment, mark
}

/// One piece of a line, with its place in the line (for syntax colours).
struct Token: Equatable, Sendable {
    enum Kind: Equatable, Sendable {
        case number(Double)
        /// A clock time such as `2:30`.
        case time(hour: Int, minute: Int)
        case word(String)
        /// An operator or bracket: `+ - * / ^ ( ) = % & | ; ° << >>`.
        case symbol(String)
        case currencySymbol(String)
        /// A `"quoted"` comment.
        case quoted
        /// A Markdown mark: `**`, `__`, `_`, `~~` or a backtick.
        case mark
    }

    var kind: Kind
    var range: Range<String.Index>
}
