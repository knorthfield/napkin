import Foundation

/// Finds a unit from the word or words that a note uses for it.
enum UnitTable {
    static let degree = UnitOfMeasure(symbol: "°", dimension: .angle, toBase: .pi / 180)
    static let radian = UnitOfMeasure(symbol: "rad", dimension: .angle, toBase: 1)
    static let inch = UnitOfMeasure(symbol: "inch", plural: "inches", dimension: .length, toBase: 0.0254)

    private struct Entry {
        var unit: UnitOfMeasure
        /// Case-sensitive short forms. The unit's own symbol is always one of them.
        var symbols: [String] = []
        /// Long forms in lower case. The form with an `s` at the end is added automatically.
        var names: [String]
        /// True if the unit takes SI prefixes: `km`, `kilometre`.
        var takesPrefixes = false
    }

    private static func entry(
        _ symbol: String, plural: String? = nil, _ dimension: UnitDimension, _ toBase: Double, offset: Double = 0,
        symbols: [String] = [], names: [String], takesPrefixes: Bool = false
    ) -> Entry {
        Entry(
            unit: UnitOfMeasure(symbol: symbol, plural: plural, dimension: dimension, toBase: toBase, offset: offset),
            symbols: symbols, names: names, takesPrefixes: takesPrefixes
        )
    }

    private static let litre = 0.001
    private static let entries: [Entry] = [
        entry("m", .length, 1, names: ["meter", "metre"], takesPrefixes: true),
        Entry(unit: inch, names: ["inch", "inches"]),
        entry("ft", .length, 0.3048, names: ["foot", "feet"]),
        entry("yd", .length, 0.9144, names: ["yard"]),
        entry("mi", .length, 1609.344, names: ["mile"]),
        entry("nmi", .length, 1852, names: ["nautical mile"]),
        entry("mil", .length, 0.0000254, names: ["mil"]),
        entry("pt", .length, 0.0254 / 72, names: ["point"]),
        entry("line", plural: "lines", .length, 0.0254 / 12, names: ["line"]),
        entry("hand", plural: "hands", .length, 0.1016, names: ["hand"]),
        entry("rod", plural: "rods", .length, 5.0292, names: ["rod"]),
        entry("chain", plural: "chains", .length, 20.1168, names: ["chain"]),
        entry("furlong", plural: "furlongs", .length, 201.168, names: ["furlong"]),
        entry("cable", plural: "cables", .length, 185.2, names: ["cable"]),
        entry("league", plural: "leagues", .length, 4828.032, names: ["league"]),

        entry("ha", .area, 10_000, names: ["hectare"]),
        entry("are", plural: "ares", .area, 100, names: ["are"]),
        entry("acre", plural: "acres", .area, 4046.8564224, names: ["acre"]),

        entry("L", .volume, litre, symbols: ["l"], names: ["liter", "litre"], takesPrefixes: true),
        entry("pint", plural: "pints", .volume, 0.473176473 * litre, names: ["pint"]),
        entry("quart", plural: "quarts", .volume, 0.946352946 * litre, names: ["quart"]),
        entry("gal", .volume, 3.785411784 * litre, names: ["gallon"]),
        entry("tsp", .volume, 0.00492892159375 * litre, names: ["teaspoon", "tea spoon"]),
        entry("tbsp", .volume, 0.01478676478125 * litre, names: ["tablespoon", "table spoon"]),
        entry("cup", plural: "cups", .volume, 0.2365882365 * litre, names: ["cup"]),

        entry("g", .mass, 1, names: ["gram", "gramme"], takesPrefixes: true),
        entry("t", .mass, 1_000_000, names: ["tonne", "ton"]),
        entry("ct", .mass, 0.2, names: ["carat"]),
        entry("centner", plural: "centners", .mass, 100_000, names: ["centner"]),
        entry("lb", .mass, 453.59237, symbols: ["lbs"], names: ["pound"]),
        entry("st", .mass, 6350.29318, names: ["stone"]),
        entry("oz", .mass, 28.349523125, names: ["ounce"]),

        entry("K", .temperature, 1, names: ["kelvin"]),
        entry("°C", .temperature, 1, offset: 273.15, symbols: ["C"], names: ["celsius"]),
        entry("°F", .temperature, 5.0 / 9, offset: 459.67 * 5 / 9, symbols: ["F"], names: ["fahrenheit"]),

        entry("s", .time, 1, symbols: ["sec"], names: ["second"], takesPrefixes: true),
        entry("min", .time, 60, names: ["minute"]),
        entry("h", .time, 3600, symbols: ["hr"], names: ["hour"]),
        entry("day", plural: "days", .time, 86400, names: ["day"]),
        entry("week", plural: "weeks", .time, 604_800, names: ["week"]),
        // A year is 365 days. A month is 1/12 of a year.
        entry("month", plural: "months", .time, 31_536_000.0 / 12, names: ["month"]),
        entry("year", plural: "years", .time, 31_536_000, symbols: ["yr"], names: ["year"]),

        Entry(unit: radian, names: ["radian"]),
        Entry(unit: degree, symbols: ["deg"], names: ["degree"]),

        entry("b", .data, 1, names: ["bit"], takesPrefixes: true),
        entry("B", .data, 8, names: ["byte"], takesPrefixes: true),
    ]

    /// Longer symbols first, so that `da` is found before `d`.
    private static let prefixes: [(symbol: String, name: String, factor: Double)] = [
        ("da", "deca", 1e1), ("da", "deka", 1e1),
        ("Q", "quetta", 1e30), ("R", "ronna", 1e27), ("Y", "yotta", 1e24), ("Z", "zetta", 1e21),
        ("E", "exa", 1e18), ("P", "peta", 1e15), ("T", "tera", 1e12), ("G", "giga", 1e9), ("M", "mega", 1e6),
        ("k", "kilo", 1e3), ("h", "hecto", 1e2), ("d", "deci", 1e-1), ("c", "centi", 1e-2), ("m", "milli", 1e-3),
        ("µ", "micro", 1e-6), ("u", "micro", 1e-6), ("n", "nano", 1e-9), ("p", "pico", 1e-12),
        ("f", "femto", 1e-15), ("a", "atto", 1e-18), ("z", "zepto", 1e-21), ("y", "yocto", 1e-24),
        ("r", "ronto", 1e-27), ("q", "quecto", 1e-30),
    ]
    /// `KiB` is 1024 bytes. `kB` is 1000 bytes.
    private static let binaryPrefixes: [(symbol: String, name: String, factor: Double)] = [
        ("Ki", "kibi", 1024), ("Mi", "mebi", pow(1024, 2)), ("Gi", "gibi", pow(1024, 3)),
        ("Ti", "tebi", pow(1024, 4)), ("Pi", "pebi", pow(1024, 5)),
    ]
    /// Words that look like a prefix with a unit but are much more frequently English words.
    private static let notUnits: Set<String> = ["at", "as", "am", "pm"]

    private static let bySymbol: [String: Entry] = Dictionary(
        entries.flatMap { entry in ([entry.unit.symbol] + entry.symbols).map { ($0, entry) } },
        uniquingKeysWith: { first, _ in first }
    )
    private static let byName: [String: Entry] = Dictionary(
        entries.flatMap { entry in entry.names.flatMap { [($0, entry), ($0 + "s", entry)] } },
        uniquingKeysWith: { first, _ in first }
    )

    /// The unit for a word or a group of words, such as `km`, `Kilometres`, `sq ft`, `m2` or `nautical miles`.
    static func unit(named text: String) -> UnitOfMeasure? {
        if let unit = plainUnit(named: text) { return unit }
        let lowercased = text.lowercased()
        for (words, dimension) in [(["square ", "sq ", "sq"], UnitDimension.area), (["cubic ", "cu ", "cb ", "cb", "cu"], .volume)] {
            for word in words where lowercased.hasPrefix(word) {
                if let unit = power(of: String(text.dropFirst(word.count)), dimension) { return unit }
            }
        }
        if let last = text.last, text.count > 1 {
            if "2²".contains(last), let unit = power(of: String(text.dropLast()), .area) { return unit }
            if "3³".contains(last), let unit = power(of: String(text.dropLast()), .volume) { return unit }
        }
        return nil
    }

    /// `sq cm` is the area of a square with sides of 1 cm.
    private static func power(of lengthName: String, _ dimension: UnitDimension) -> UnitOfMeasure? {
        guard let length = plainUnit(named: lengthName), length.dimension == .length else { return nil }
        let exponent = dimension == .area ? 2.0 : 3.0
        return UnitOfMeasure(symbol: length.symbol + (dimension == .area ? "²" : "³"), dimension: dimension,
                    toBase: pow(length.toBase, exponent))
    }

    private static func plainUnit(named text: String) -> UnitOfMeasure? {
        if notUnits.contains(text) { return nil }
        if let entry = bySymbol[text] { return entry.unit }
        let lowercased = text.lowercased()
        if let entry = byName[lowercased] { return entry.unit }
        for (prefix, isBinary) in prefixes.map({ ($0, false) }) + binaryPrefixes.map({ ($0, true) }) {
            var entry = text.hasPrefix(prefix.symbol) ? bySymbol[String(text.dropFirst(prefix.symbol.count))] : nil
            if entry == nil, lowercased.hasPrefix(prefix.name) {
                entry = byName[String(lowercased.dropFirst(prefix.name.count))]
            }
            if let entry, entry.takesPrefixes, !isBinary || entry.unit.dimension == .data {
                return prefixed(entry.unit, prefix.symbol, prefix.factor)
            }
        }
        return nil
    }

    private static func prefixed(_ unit: UnitOfMeasure, _ prefix: String, _ factor: Double) -> UnitOfMeasure {
        UnitOfMeasure(symbol: (prefix == "u" ? "µ" : prefix) + unit.symbol, dimension: unit.dimension, toBase: unit.toBase * factor)
    }
}
