import Testing
@testable import Napkin

struct UnitTests {
    @Test(arguments: [
        ("5 km", "5 km"), ("5 kilometres", "5 km"), ("5 Kilometers", "5 km"), ("1 inch", "1 inch"),
        ("20 inches in cm", "50.8 cm"), ("1 mile in km", "1.61 km"), ("1 km in m", "1,000 m"),
        ("3 feet in inches", "36 inches"), ("1 yard to ft", "3 ft"), ("1 nautical mile in m", "1,852 m"),
        ("2 picometers in m", "2e-12 m"), ("1 mm into µm", "1,000 µm"), ("5 in km", "5 km"),
        ("1 furlong as chains", "10 chains"), ("72 points in inches", "1 inch"),
    ])
    func length(text: String, expected: String) {
        #expect(result(text) == expected)
    }

    @Test(arguments: [
        ("1 kg in g", "1,000 g"), ("1 pound in grams", "453.59 g"), ("1 stone in lb", "14 lb"),
        ("16 oz in lbs", "1 lb"), ("2 tonnes in kg", "2,000 kg"), ("5 carats in g", "1 g"),
        ("1 centner in kg", "100 kg"),
    ])
    func weight(text: String, expected: String) {
        #expect(result(text) == expected)
    }

    @Test(arguments: [
        ("20 sq cm", "20 cm²"), ("30 square inches in sq cm", "193.55 cm²"), ("11 sqm", "11 m²"),
        ("1 hectare in m2", "10,000 m²"), ("1 acre in ares", "40.47 ares"), ("1 km² in ha", "100 ha"),
        ("20 cu cm", "20 cm³"), ("11 cbm in litres", "11,000 L"), ("1 cubic meter in L", "1,000 L"),
        ("1 gallon in pints", "8 pints"), ("1 cup in ml", "236.59 mL"), ("3 tea spoons in tbsp", "1 tbsp"),
        ("1 quart in cups", "4 cups"), ("500 ml in l", "0.5 L"),
    ])
    func areaAndVolume(text: String, expected: String) {
        #expect(result(text) == expected)
    }

    @Test(arguments: [
        ("0 °C in K", "273.15 K"), ("100 celsius in fahrenheit", "212 °F"), ("32 °F in °C", "0 °C"),
        ("300 kelvin in C", "26.85 °C"), ("20 °C + 5", "25 °C"),
    ])
    func temperature(text: String, expected: String) {
        #expect(result(text) == expected)
    }

    @Test(arguments: [
        ("90 min in hours", "1.5 h"), ("1 day in seconds", "86,400 s"), ("2 weeks in days", "14 days"),
        ("round(1 month in days)", "30 days"), ("1 year in days", "365 days"), ("500 ms in s", "0.5 s"),
        ("1 hr in min", "60 min"), ("180° in radians", "3.14 rad"), ("pi radians in degrees", "180°"),
        ("1 week", "1 week"),
    ])
    func timeAndAngle(text: String, expected: String) {
        #expect(result(text) == expected)
    }

    @Test(arguments: [
        ("3 GB in MB", "3,000 MB"), ("1 kibibyte in bytes", "1,024 B"), ("1 GiB in MiB", "1,024 MiB"),
        ("1 byte in bits", "8 b"), ("1 MB in Mb", "8 Mb"), ("2 megabytes in kB", "2,000 kB"),
    ])
    func data(text: String, expected: String) {
        #expect(result(text) == expected)
    }

    @Test(arguments: [
        ("12 pt in px", "16 px"), ("1 inch in px", "96 px"), ("1.2 em in px", "19.2 px"),
        ("em = 20px\n1.2 em in px", "24 px"), ("ppi = 326\n1 cm in px", "128.35 px"),
        ("em = 10\n2 em in px", "20 px"),
    ])
    func screenUnits(text: String, expected: String) {
        #expect(result(text) == expected)
    }

    @Test(arguments: [
        ("1 meter 20 cm", "120 cm"), ("1 km + 5 m", "1,005 m"), ("5 ft 6 inches in cm", "167.64 cm"),
        ("2 hours - 30 min", "90 min"), ("10 km / 2", "5 km"), ("3 * 2 kg", "6 kg"), ("10 km / 2 km", "5"),
        ("10 km - 10%", "9 km"), ("20% of 50 kg", "10 kg"), ("1 km as a % of 4 km", "25%"),
        ("-5 m", "-5 m"), ("2k m", "2,000 m"), ("d = 5 km\nd in m", "5,000 m"), ("3 km\n2 km\nsum", "5 km"),
        ("(1 km + 500 m) in miles", "0.93 mi"), ("5 km\nprev in m", "5,000 m"),
    ])
    func arithmetic(text: String, expected: String) {
        #expect(result(text) == expected)
    }

    @Test(arguments: ["5 km + 3 kg", "5 km in kg", "2 ^ 3 km", "10 / 2 km", "5% in km"])
    func measurementsThatDoNotGoTogether(text: String) {
        #expect(result(text) == nil)
    }

    @Test(arguments: [
        ("there are 5", "5"), ("5 at 3", nil), ("5 m\nm = 2\n3 m", nil), ("5 in a box", "5"),
        ("h = 3\n2 * h", "6"),
    ])
    func wordsThatLookLikeUnits(text: String, expected: String?) {
        #expect(result(text) == expected)
    }
}
