import Foundation
import Testing
@testable import Napkin

/// Saturday 14 November 2026, 12:00 in London (UTC).
let fixedClock = EvaluationContext(
    now: Date(timeIntervalSince1970: 1_794_657_600), timeZone: TimeZone(identifier: "UTC")!,
    locale: Locale(identifier: "en_GB")
)

struct DateTests {
    @Test(arguments: [
        ("now", "14 Nov 2026 at 12:00"), ("time", "12:00"), ("today", "Sat, 14 Nov 2026"),
        ("tomorrow", "Sun, 15 Nov 2026"), ("yesterday", "Fri, 13 Nov 2026"),
        ("today + 2 weeks", "Sat, 28 Nov 2026"), ("2 weeks + today", "Sat, 28 Nov 2026"),
        ("today - 1 month", "Wed, 14 Oct 2026"), ("today + 1 year", "Sun, 14 Nov 2027"),
        ("now + 3 hours", "14 Nov 2026 at 15:00"), ("today + 90 min", "14 Nov 2026 at 01:30"),
        ("today + 1.5 days", "15 Nov 2026 at 12:00"), ("fromunix(1446587186)", "3 Nov 2015 at 21:46"),
        ("2:30 pm", "14:30"), ("14:30", "14:30"), ("12 am", "00:00"), ("12:15 pm", "12:15"),
        ("9 am + 45 min", "09:45"), ("d = today\nd + 3 days", "Tue, 17 Nov 2026"),
    ])
    func dates(text: String, expected: String) {
        #expect(result(text, context: fixedClock) == expected)
    }

    @Test(arguments: ["today * 2", "today + 5", "today + 3 km", "-today", "today in km", "25:00"])
    func datesWithNoResult(text: String) {
        #expect(result(text, context: fixedClock) == nil)
    }
}
