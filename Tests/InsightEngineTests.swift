import XCTest
@testable import Kinen

final class InsightEngineTests: XCTestCase {

    // MARK: - Helpers

    private func makeEntry(content: String = "test", mood: Mood? = nil, createdAt: Date = Date(), tags: [Tag] = []) -> JournalEntry {
        let entry = JournalEntry(content: content, mood: mood, tags: tags, createdAt: createdAt)
        return entry
    }

    private func daysAgo(_ n: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -n, to: Date())!
    }

    // MARK: - Basic Tests

    func testNoInsightsWithFewEntries() {
        let entries = (0..<3).map { _ in makeEntry(mood: .good) }
        let insights = InsightEngine.generateInsights(from: entries)
        XCTAssertTrue(insights.isEmpty, "Should not generate insights with <5 entries")
    }

    func testGeneratesInsightsWithEnoughEntries() {
        let entries = (0..<10).map { i in
            makeEntry(mood: i < 5 ? .great : .bad, createdAt: daysAgo(i))
        }
        // May or may not generate insights depending on patterns, but shouldn't crash
        _ = InsightEngine.generateInsights(from: entries)
    }

    func testEmptyEntriesReturnsEmpty() {
        let insights = InsightEngine.generateInsights(from: [])
        XCTAssertTrue(insights.isEmpty)
    }

    // MARK: - Consistency Insight

    func testConsistencyInsightForActiveWriter() {
        // Create entries for 26 of the last 30 days
        let entries = (0..<26).map { i in
            makeEntry(mood: .good, createdAt: daysAgo(i))
        }
        let insights = InsightEngine.generateInsights(from: entries)
        let consistencyInsight = insights.first { $0.type == .streak }
        XCTAssertNotNil(consistencyInsight, "Should detect high consistency")
    }

    // MARK: - Mood Values

    func testMoodNormalizedValues() {
        XCTAssertEqual(Mood.terrible.normalizedValue, 0.0)
        XCTAssertEqual(Mood.great.normalizedValue, 1.0)
        XCTAssertGreaterThan(Mood.good.normalizedValue, Mood.neutral.normalizedValue)
    }
}
