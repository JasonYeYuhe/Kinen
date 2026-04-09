import XCTest
@testable import Kinen

final class RecapGeneratorTests: XCTestCase {
    func testEmptyWeeklyRecap() {
        let recap = RecapGenerator.weeklyRecap(entries: [], weekOf: Date())
        XCTAssertEqual(recap.entryCount, 0)
        XCTAssertEqual(recap.totalWords, 0)
        XCTAssertNil(recap.averageMood)
        XCTAssertEqual(recap.moodTrend, .insufficient)
    }

    func testFormatForExport() {
        let recap = RecapGenerator.weeklyRecap(entries: [], weekOf: Date())
        let text = RecapGenerator.formatForExport(recap)
        XCTAssertTrue(text.contains("Kinen Journal Recap"))
        XCTAssertTrue(text.contains("on-device"))
    }

    func testMoodTrendLabels() {
        XCTAssertEqual(RecapGenerator.MoodTrend.improving.rawValue, "Improving")
        XCTAssertEqual(RecapGenerator.MoodTrend.declining.emoji, "📉")
        XCTAssertEqual(RecapGenerator.MoodTrend.stable.emoji, "➡️")
    }
}
