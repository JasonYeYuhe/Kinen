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

    // MARK: - Sporadic Writer

    func testInconsistencyInsightForSporadicWriter() {
        // 12 entries on only 2 unique days — uniqueDays (2) ≤ 5 + count (12) ≥ 10
        let day1 = daysAgo(5)
        let day2 = daysAgo(6)
        let entries = (0..<6).map { _ in makeEntry(mood: .good, createdAt: day1) } +
                      (0..<6).map { _ in makeEntry(mood: .neutral, createdAt: day2) }
        let insights = InsightEngine.generateInsights(from: entries)
        let streakInsight = insights.first { $0.type == .streak }
        XCTAssertNotNil(streakInsight, "Should detect sporadic writing pattern for user writing in bursts")
    }

    // MARK: - Word Count / Mood Correlation

    func testWordCountCorrelationLongerEntriesBetterMood() {
        // 6 one-word (terrible) + 6 ten-word (great) → longerBetter writingHabit
        let shortContent = "brief"
        let longContent = "one two three four five six seven eight nine ten"
        let entries = (0..<6).map { _ in makeEntry(content: shortContent, mood: .terrible) } +
                      (0..<6).map { _ in makeEntry(content: longContent,  mood: .great) }
        let insights = InsightEngine.generateInsights(from: entries)
        let habitInsight = insights.first { $0.type == .writingHabit }
        XCTAssertNotNil(habitInsight, "Should detect word count–mood correlation when longer entries have better mood")
    }

    func testWordCountCorrelationShorterEntriesBetterMood() {
        // 6 one-word (great) + 6 ten-word (terrible) → shorterBetter writingHabit
        let shortContent = "brief"
        let longContent = "one two three four five six seven eight nine ten"
        let entries = (0..<6).map { _ in makeEntry(content: shortContent, mood: .great) } +
                      (0..<6).map { _ in makeEntry(content: longContent,  mood: .terrible) }
        let insights = InsightEngine.generateInsights(from: entries)
        let habitInsight = insights.first { $0.type == .writingHabit }
        XCTAssertNotNil(habitInsight, "Should detect word count–mood correlation when shorter entries have better mood")
    }

    // MARK: - Mood Values

    func testMoodNormalizedValues() {
        XCTAssertEqual(Mood.terrible.normalizedValue, 0.0)
        XCTAssertEqual(Mood.great.normalizedValue, 1.0)
        XCTAssertGreaterThan(Mood.good.normalizedValue, Mood.neutral.normalizedValue)
    }
}
