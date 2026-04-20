import XCTest
@testable import Kinen

final class DateExtensionsTests: XCTestCase {
    func testStartOfDay() {
        let now = Date()
        let start = now.startOfDay
        let components = Calendar.current.dateComponents([.hour, .minute, .second], from: start)
        XCTAssertEqual(components.hour, 0)
        XCTAssertEqual(components.minute, 0)
    }

    func testEndOfDay() {
        let now = Date()
        let end = now.endOfDay
        let components = Calendar.current.dateComponents([.hour, .minute, .second], from: end)
        XCTAssertEqual(components.hour, 23)
        XCTAssertEqual(components.minute, 59)
        XCTAssertEqual(components.second, 59)
    }

    func testIsToday() {
        XCTAssertTrue(Date().isToday)
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        XCTAssertFalse(yesterday.isToday)
    }

    func testIsYesterday() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        XCTAssertTrue(yesterday.isYesterday)
        XCTAssertFalse(Date().isYesterday)
        let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: Date())!
        XCTAssertFalse(twoDaysAgo.isYesterday)
    }

    func testDayOfWeek() {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        XCTAssertEqual(Date().dayOfWeek, weekday)
        XCTAssertGreaterThanOrEqual(Date().dayOfWeek, 1)
        XCTAssertLessThanOrEqual(Date().dayOfWeek, 7)
    }

    func testWeekdayName() {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        let expected = formatter.string(from: Date())
        XCTAssertEqual(Date().weekdayName, expected)
        XCTAssertFalse(Date().weekdayName.isEmpty)
    }

    func testDatesInMonth() {
        let calendar = Calendar.current
        let components = DateComponents(year: 2024, month: 2)
        let feb2024 = calendar.date(from: components)!
        let dates = Date.datesInMonth(of: feb2024)
        // 2024 is a leap year, February has 29 days
        XCTAssertEqual(dates.count, 29)
        // All dates should be in February 2024
        for date in dates {
            let month = calendar.component(.month, from: date)
            let year = calendar.component(.year, from: date)
            XCTAssertEqual(month, 2)
            XCTAssertEqual(year, 2024)
        }
    }

    func testDatesInMonthNonLeapYear() {
        let calendar = Calendar.current
        let components = DateComponents(year: 2023, month: 2)
        let feb2023 = calendar.date(from: components)!
        let dates = Date.datesInMonth(of: feb2023)
        // 2023 is not a leap year, February has 28 days
        XCTAssertEqual(dates.count, 28)
    }

    func testDatesInMonthJanuary() {
        let calendar = Calendar.current
        let components = DateComponents(year: 2025, month: 1)
        let jan2025 = calendar.date(from: components)!
        let dates = Date.datesInMonth(of: jan2025)
        XCTAssertEqual(dates.count, 31)
    }

    func testDaysAgo() {
        let weekAgo = Date.daysAgo(7)
        let diff = Calendar.current.dateComponents([.day], from: weekAgo, to: Date()).day!
        XCTAssertEqual(diff, 7)
    }

    func testDaysAgoZero() {
        let today = Date.daysAgo(0)
        XCTAssertTrue(Calendar.current.isDateInToday(today))
    }

    func testFormattedDuration() {
        XCTAssertEqual(TimeInterval(65).formattedDuration, "1m 5s")
        XCTAssertEqual(TimeInterval(3700).formattedDuration, "1h 1m")
        XCTAssertEqual(TimeInterval(30).formattedDuration, "30s")
    }

    func testFormattedDurationZero() {
        XCTAssertEqual(TimeInterval(0).formattedDuration, "0s")
    }

    func testFormattedDurationExactHour() {
        XCTAssertEqual(TimeInterval(3600).formattedDuration, "1h 0m")
    }

    func testConsecutiveDays() {
        let calendar = Calendar.current
        let today = Date().startOfDay
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!
        let dates: Set<Date> = [today, yesterday, twoDaysAgo]
        XCTAssertEqual(today.consecutiveDays(in: dates), 3)
    }

    func testConsecutiveDaysGap() {
        let calendar = Calendar.current
        let today = Date().startOfDay
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!
        // Gap: no yesterday — streak is 1
        let dates: Set<Date> = [today, twoDaysAgo]
        XCTAssertEqual(today.consecutiveDays(in: dates), 1)
    }

    func testConsecutiveDaysEmpty() {
        let today = Date().startOfDay
        let dates: Set<Date> = []
        XCTAssertEqual(today.consecutiveDays(in: dates), 0)
    }

    // MARK: - shortDate

    func testShortDateIsNonEmpty() {
        let s = Date().shortDate
        XCTAssertFalse(s.isEmpty, "shortDate should produce a non-empty string")
        XCTAssertFalse(s.trimmingCharacters(in: .whitespaces).isEmpty)
    }

    func testShortDateDiffersAcrossDays() {
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        XCTAssertNotEqual(today.shortDate, yesterday.shortDate,
                          "shortDate for different days should differ")
    }

    // MARK: - relativeDescription

    func testRelativeDescriptionIsNonEmpty() {
        XCTAssertFalse(Date().relativeDescription.isEmpty,
                       "relativeDescription for now should be non-empty")
    }

    func testRelativeDescriptionPastDate() {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let desc = weekAgo.relativeDescription
        XCTAssertFalse(desc.isEmpty, "relativeDescription for a past date should be non-empty")
        // RelativeDateTimeFormatter always produces output; just verify it ran
        XCTAssertNotEqual(desc, Date().relativeDescription,
                          "Relative descriptions for different dates should differ")
    }
}
