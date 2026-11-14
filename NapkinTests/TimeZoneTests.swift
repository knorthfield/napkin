import Testing
@testable import Napkin

struct TimeZoneTests {
    @Test(arguments: [
        ("time in Madrid", "13:00"), ("Time in madrid", "13:00"), ("New York time", "07:00"),
        ("PST time", "04:00"), ("now in Ho Chi Minh", "14 Nov 2026 at 19:00"),
        ("2:30 pm HKT in Berlin", "07:30"), ("5 pm in Tokyo", "02:00"), ("9 am New York in London", "14:00"),
        ("time in UTC", "12:00"), ("today in Tokyo", "Sat, 14 Nov 2026"),
    ])
    func zones(text: String, expected: String) {
        #expect(result(text, context: fixedClock) == expected)
    }

    @Test(arguments: [("time in Atlantis", nil), ("dinner in Paris 50", nil), ("5 est", "5"), ("Madrid 5", "5")])
    func wordsThatAreNotATimeZoneHere(text: String, expected: String?) {
        #expect(result(text, context: fixedClock) == expected)
    }
}
