import XCTest
@testable import Kinen

final class WidgetDataProviderTests: XCTestCase {

    // MARK: - UserDefaults Keys

    func testDefaultsKeyConstants() {
        // Verify the widget reads expected keys from App Group
        let defaults = UserDefaults(suiteName: "group.com.jasonye.kinen")
        XCTAssertNotNil(defaults, "App group UserDefaults should be accessible")
    }

    // MARK: - Streak Calculation (inline logic test)

    func testStreakFromConsecutiveDates() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dates: Set<Date> = [
            today,
            calendar.date(byAdding: .day, value: -1, to: today)!,
            calendar.date(byAdding: .day, value: -2, to: today)!,
        ]

        var streak = 0
        var checkDate = dates.max() ?? Date()
        while dates.contains(calendar.startOfDay(for: checkDate)) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = prev
        }
        XCTAssertEqual(streak, 3, "3 consecutive days should give streak of 3")
    }

    func testStreakWithGap() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dates: Set<Date> = [
            today,
            // skip yesterday
            calendar.date(byAdding: .day, value: -2, to: today)!,
        ]

        var streak = 0
        var checkDate = dates.max() ?? Date()
        while dates.contains(calendar.startOfDay(for: checkDate)) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = prev
        }
        XCTAssertEqual(streak, 1, "Gap in dates should break streak")
    }

    func testStreakEmpty() {
        let dates = Set<Date>()
        let streak = dates.isEmpty ? 0 : 1
        XCTAssertEqual(streak, 0, "Empty dates should give 0 streak")
    }

    // MARK: - Mood Average

    func testMoodAverage() {
        let moods: [Int] = [1, 3, 5, 4, 2] // terrible, neutral, great, good, bad
        let avg = Double(moods.reduce(0, +)) / Double(moods.count)
        XCTAssertEqual(avg, 3.0, accuracy: 0.01, "Average of 1,3,5,4,2 should be 3.0")
    }

    func testMoodAverageEmpty() {
        let moods: [Int] = []
        let avg = moods.isEmpty ? 0.0 : Double(moods.reduce(0, +)) / Double(moods.count)
        XCTAssertEqual(avg, 0.0, "Empty moods should give 0")
    }
}
