import XCTest
@testable import Kinen

final class RecapGeneratorTests: XCTestCase {

    // MARK: - Helpers

    private func makeEntry(
        content: String = "test",
        mood: Mood? = nil,
        sentimentScore: Double? = nil,
        createdAt: Date = Date()
    ) -> JournalEntry {
        let entry = JournalEntry(content: content, mood: mood, createdAt: createdAt)
        entry.sentimentScore = sentimentScore
        return entry
    }

    private func thisWeekDate(dayOffset: Int) -> Date {
        let cal = Calendar.current
        let startOfWeek = cal.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        return cal.date(byAdding: .day, value: dayOffset, to: startOfWeek)!
    }

    private func thisMonthDate(dayOffset: Int) -> Date {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: Date())
        let startOfMonth = cal.date(from: comps)!
        return cal.date(byAdding: .day, value: dayOffset, to: startOfMonth)!
    }

    // MARK: - Empty Recap

    func testEmptyWeeklyRecap() {
        let recap = RecapGenerator.weeklyRecap(entries: [], weekOf: Date())
        XCTAssertEqual(recap.entryCount, 0)
        XCTAssertEqual(recap.totalWords, 0)
        XCTAssertNil(recap.averageMood)
        XCTAssertEqual(recap.moodTrend, .insufficient)
    }

    // MARK: - Weekly Recap with Entries

    func testWeeklyRecapWithEntries() {
        let entries = (0..<5).map { i in
            makeEntry(content: "words words words", mood: .good, createdAt: thisWeekDate(dayOffset: i))
        }
        let recap = RecapGenerator.weeklyRecap(entries: entries, weekOf: Date())
        XCTAssertEqual(recap.entryCount, 5)
        XCTAssertEqual(recap.totalWords, 15) // "words words words" = 3 words × 5 entries
        XCTAssertNotNil(recap.averageMood)
        XCTAssertEqual(recap.averageMood!, Double(Mood.good.rawValue), accuracy: 0.01)
    }

    func testWeeklyRecapExcludesOtherWeeks() {
        let cal = Calendar.current
        let startOfLastWeek = cal.date(byAdding: .weekOfYear, value: -1, to: thisWeekDate(dayOffset: 0))!
        let thisWeekEntry = makeEntry(content: "this week", createdAt: thisWeekDate(dayOffset: 0))
        let lastWeekEntry = makeEntry(content: "old entry", createdAt: startOfLastWeek)
        let recap = RecapGenerator.weeklyRecap(entries: [thisWeekEntry, lastWeekEntry], weekOf: Date())
        XCTAssertEqual(recap.entryCount, 1)
    }

    // MARK: - Monthly Recap

    func testMonthlyRecapWithEntries() {
        let entries = (1...3).map { i in
            makeEntry(content: "month entry", createdAt: thisMonthDate(dayOffset: i))
        }
        let cal = Calendar.current
        let lastMonthDate = cal.date(byAdding: .month, value: -1, to: thisMonthDate(dayOffset: 1))!
        let lastMonthEntry = makeEntry(content: "last month", createdAt: lastMonthDate)

        let recap = RecapGenerator.monthlyRecap(entries: entries + [lastMonthEntry], monthOf: Date())
        XCTAssertEqual(recap.entryCount, 3)
    }

    // MARK: - Mood Trend

    func testMoodTrendImproving() {
        // First half negative, second half positive
        let entries = [
            makeEntry(sentimentScore: -0.6, createdAt: thisWeekDate(dayOffset: 0)),
            makeEntry(sentimentScore: -0.5, createdAt: thisWeekDate(dayOffset: 0)),
            makeEntry(sentimentScore: -0.4, createdAt: thisWeekDate(dayOffset: 0)),
            makeEntry(sentimentScore: 0.5, createdAt: thisWeekDate(dayOffset: 0)),
            makeEntry(sentimentScore: 0.6, createdAt: thisWeekDate(dayOffset: 0)),
            makeEntry(sentimentScore: 0.7, createdAt: thisWeekDate(dayOffset: 0)),
        ]
        let recap = RecapGenerator.weeklyRecap(entries: entries, weekOf: Date())
        XCTAssertEqual(recap.moodTrend, .improving)
    }

    func testMoodTrendDeclining() {
        // First half positive, second half negative
        let entries = [
            makeEntry(sentimentScore: 0.6, createdAt: thisWeekDate(dayOffset: 0)),
            makeEntry(sentimentScore: 0.5, createdAt: thisWeekDate(dayOffset: 0)),
            makeEntry(sentimentScore: 0.4, createdAt: thisWeekDate(dayOffset: 0)),
            makeEntry(sentimentScore: -0.5, createdAt: thisWeekDate(dayOffset: 0)),
            makeEntry(sentimentScore: -0.6, createdAt: thisWeekDate(dayOffset: 0)),
            makeEntry(sentimentScore: -0.7, createdAt: thisWeekDate(dayOffset: 0)),
        ]
        let recap = RecapGenerator.weeklyRecap(entries: entries, weekOf: Date())
        XCTAssertEqual(recap.moodTrend, .declining)
    }

    func testMoodTrendStable() {
        // All entries with low-variation sentiment
        let entries = (0..<5).map { _ in
            makeEntry(sentimentScore: 0.05, createdAt: thisWeekDate(dayOffset: 0))
        }
        let recap = RecapGenerator.weeklyRecap(entries: entries, weekOf: Date())
        XCTAssertEqual(recap.moodTrend, .stable)
    }

    func testMoodTrendInsufficientWithTwoEntries() {
        let entries = [
            makeEntry(sentimentScore: 0.5, createdAt: thisWeekDate(dayOffset: 0)),
            makeEntry(sentimentScore: 0.6, createdAt: thisWeekDate(dayOffset: 1)),
        ]
        let recap = RecapGenerator.weeklyRecap(entries: entries, weekOf: Date())
        XCTAssertEqual(recap.moodTrend, .insufficient)
    }

    // MARK: - Highlights and Challenges

    func testHighlightsFromPositiveEntries() {
        let entries = [
            makeEntry(content: "wonderful day full of joy", sentimentScore: 0.8, createdAt: thisWeekDate(dayOffset: 0)),
            makeEntry(content: "amazing progress today", sentimentScore: 0.9, createdAt: thisWeekDate(dayOffset: 1)),
            makeEntry(content: "feeling really low", sentimentScore: -0.8, createdAt: thisWeekDate(dayOffset: 2)),
        ]
        let recap = RecapGenerator.weeklyRecap(entries: entries, weekOf: Date())
        XCTAssertFalse(recap.highlights.isEmpty, "Positive entries should populate highlights")
        XCTAssertFalse(recap.challenges.isEmpty, "Negative entries should populate challenges")
    }

    func testNeutralEntriesProduceNoHighlightsOrChallenges() {
        let entries = (0..<4).map { i in
            makeEntry(content: "normal day", sentimentScore: 0.1, createdAt: thisWeekDate(dayOffset: i))
        }
        let recap = RecapGenerator.weeklyRecap(entries: entries, weekOf: Date())
        XCTAssertTrue(recap.highlights.isEmpty, "Near-neutral entries should not produce highlights")
        XCTAssertTrue(recap.challenges.isEmpty, "Near-neutral entries should not produce challenges")
    }

    // MARK: - Format for Export

    func testFormatForExport() {
        let recap = RecapGenerator.weeklyRecap(entries: [], weekOf: Date())
        let text = RecapGenerator.formatForExport(recap)
        XCTAssertTrue(text.contains("Kinen Journal Recap"))
        XCTAssertTrue(text.contains("on-device"))
    }

    func testFormatForExportIncludesAllSections() {
        let entries = (0..<5).map { i in
            makeEntry(content: "test entry", mood: .good, sentimentScore: Double(i) * 0.05,
                      createdAt: thisWeekDate(dayOffset: i))
        }
        let recap = RecapGenerator.weeklyRecap(entries: entries, weekOf: Date())
        let text = RecapGenerator.formatForExport(recap)
        XCTAssertTrue(text.contains("Overview"))
        XCTAssertTrue(text.contains("Growth Note"))
        XCTAssertTrue(text.contains("Suggested Action"))
    }

    func testFormatForExportIncludesAverageMood() {
        let entries = [makeEntry(mood: .great, createdAt: thisWeekDate(dayOffset: 0))]
        let recap = RecapGenerator.weeklyRecap(entries: entries, weekOf: Date())
        let text = RecapGenerator.formatForExport(recap)
        XCTAssertTrue(text.contains("Average mood"))
    }

    // MARK: - MoodTrend Labels and Emoji

    func testMoodTrendLabels() {
        XCTAssertEqual(RecapGenerator.MoodTrend.improving.rawValue, "Improving")
        XCTAssertEqual(RecapGenerator.MoodTrend.declining.emoji, "📉")
        XCTAssertEqual(RecapGenerator.MoodTrend.stable.emoji, "➡️")
        XCTAssertEqual(RecapGenerator.MoodTrend.insufficient.emoji, "❓")
        XCTAssertEqual(RecapGenerator.MoodTrend.improving.emoji, "📈")
    }
}
