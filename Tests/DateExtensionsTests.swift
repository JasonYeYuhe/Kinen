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

    func testIsToday() {
        XCTAssertTrue(Date().isToday)
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        XCTAssertFalse(yesterday.isToday)
    }

    func testDaysAgo() {
        let weekAgo = Date.daysAgo(7)
        let diff = Calendar.current.dateComponents([.day], from: weekAgo, to: Date()).day!
        XCTAssertEqual(diff, 7)
    }

    func testFormattedDuration() {
        XCTAssertEqual(TimeInterval(65).formattedDuration, "1m 5s")
        XCTAssertEqual(TimeInterval(3700).formattedDuration, "1h 1m")
        XCTAssertEqual(TimeInterval(30).formattedDuration, "30s")
    }

    func testConsecutiveDays() {
        let calendar = Calendar.current
        let today = Date().startOfDay
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!
        let dates: Set<Date> = [today, yesterday, twoDaysAgo]
        XCTAssertEqual(today.consecutiveDays(in: dates), 3)
    }
}
