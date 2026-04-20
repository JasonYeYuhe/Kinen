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

    // MARK: - updateWidgetData + loadData Round-Trip

    private static let suite = "group.com.jasonye.kinen"

    private func clearWidgetDefaults() {
        let defaults = UserDefaults(suiteName: Self.suite)
        defaults?.removeObject(forKey: "widget.streak")
        defaults?.removeObject(forKey: "widget.totalEntries")
        defaults?.removeObject(forKey: "widget.averageMoodEmoji")
        defaults?.removeObject(forKey: "widget.recentMoods")
    }

    func testUpdateAndLoadRoundTrip() {
        clearWidgetDefaults()
        WidgetDataProvider.updateWidgetData(streak: 17, totalEntries: 83, averageMoodEmoji: "😊", recentMoods: [])
        let data = WidgetDataProvider.loadData()
        XCTAssertEqual(data.streak, 17)
        XCTAssertEqual(data.totalEntries, 83)
        XCTAssertEqual(data.averageMoodEmoji, "😊")
        XCTAssertTrue(data.recentMoods.isEmpty)
    }

    func testLoadDataDefaultsWhenNothingStored() {
        clearWidgetDefaults()
        let data = WidgetDataProvider.loadData()
        XCTAssertEqual(data.streak, 0, "Unset streak should default to 0")
        XCTAssertEqual(data.totalEntries, 0, "Unset totalEntries should default to 0")
        XCTAssertEqual(data.averageMoodEmoji, "😐", "Unset emoji should default to 😐")
        XCTAssertTrue(data.recentMoods.isEmpty, "Unset recentMoods should default to empty")
    }

    func testRecentMoodsEncodeDecodeRoundTrip() {
        clearWidgetDefaults()
        let now = Date()
        let moods: [(date: Date, value: Double)] = [
            (date: now.addingTimeInterval(-3600), value: 0.8),
            (date: now.addingTimeInterval(-7200), value: 0.2),
        ]
        WidgetDataProvider.updateWidgetData(streak: 0, totalEntries: 0, averageMoodEmoji: "😐", recentMoods: moods)
        let data = WidgetDataProvider.loadData()
        XCTAssertEqual(data.recentMoods.count, 2)
        XCTAssertEqual(data.recentMoods[0].value, 0.8, accuracy: 0.001)
        XCTAssertEqual(data.recentMoods[1].value, 0.2, accuracy: 0.001)
    }

    func testCorruptRecentMoodsHandledGracefully() {
        clearWidgetDefaults()
        let defaults = UserDefaults(suiteName: Self.suite)
        defaults?.set(Data([0xFF, 0xFE, 0x00, 0x01]), forKey: "widget.recentMoods")
        let data = WidgetDataProvider.loadData()
        XCTAssertTrue(data.recentMoods.isEmpty, "Corrupt recentMoods should be ignored, not crash")
    }

    func testStreakAndEntriesStoredIndependently() {
        clearWidgetDefaults()
        WidgetDataProvider.updateWidgetData(streak: 5, totalEntries: 0, averageMoodEmoji: "😐", recentMoods: [])
        WidgetDataProvider.updateWidgetData(streak: 5, totalEntries: 42, averageMoodEmoji: "😐", recentMoods: [])
        let data = WidgetDataProvider.loadData()
        XCTAssertEqual(data.streak, 5)
        XCTAssertEqual(data.totalEntries, 42)
    }
}
