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

    // MARK: - growthNote stable branches (avg >= 3.5 vs < 3.5)

    func testGrowthNoteStableHighMoodDiffersFromLow() {
        // great rawValue=5, avg=5.0 >= 3.5 → stablePositive
        let highEntries = (0..<5).map { i in
            makeEntry(mood: .great, sentimentScore: 0.1, createdAt: thisWeekDate(dayOffset: i))
        }
        // neutral rawValue=3, avg=3.0 < 3.5 → stableNeutral
        let lowEntries = (0..<5).map { i in
            makeEntry(mood: .neutral, sentimentScore: 0.1, createdAt: thisWeekDate(dayOffset: i))
        }
        let highRecap = RecapGenerator.weeklyRecap(entries: highEntries, weekOf: Date())
        let lowRecap = RecapGenerator.weeklyRecap(entries: lowEntries, weekOf: Date())
        XCTAssertEqual(highRecap.moodTrend, RecapGenerator.MoodTrend.stable)
        XCTAssertEqual(lowRecap.moodTrend, RecapGenerator.MoodTrend.stable)
        XCTAssertFalse(highRecap.growthNote.isEmpty)
        XCTAssertFalse(lowRecap.growthNote.isEmpty)
        XCTAssertNotEqual(highRecap.growthNote, lowRecap.growthNote,
                          "stable+avg≥3.5 → stablePositive; stable+avg<3.5 → stableNeutral")
    }

    func testGrowthNoteBoundaryGoodVsBadMood() {
        // good rawValue=4, avg=4.0 >= 3.5 → stablePositive
        let goodEntries = (0..<5).map { i in
            makeEntry(mood: .good, sentimentScore: 0.05, createdAt: thisWeekDate(dayOffset: i))
        }
        // bad rawValue=2, avg=2.0 < 3.5 → stableNeutral
        let badEntries = (0..<5).map { i in
            makeEntry(mood: .bad, sentimentScore: 0.05, createdAt: thisWeekDate(dayOffset: i))
        }
        let goodRecap = RecapGenerator.weeklyRecap(entries: goodEntries, weekOf: Date())
        let badRecap = RecapGenerator.weeklyRecap(entries: badEntries, weekOf: Date())
        XCTAssertEqual(goodRecap.moodTrend, RecapGenerator.MoodTrend.stable)
        XCTAssertNotEqual(goodRecap.growthNote, badRecap.growthNote,
                          "Mood.good avg=4.0 and Mood.bad avg=2.0 should produce different stable growth notes")
    }

    // MARK: - actionItem paths

    func testActionItemDecliningWithChallengesUsesDecliningPath() {
        // declining trend (first half positive → second half negative) + challenge entries
        let entries = [
            makeEntry(sentimentScore: 0.8, createdAt: thisWeekDate(dayOffset: 0)),
            makeEntry(sentimentScore: 0.7, createdAt: thisWeekDate(dayOffset: 1)),
            makeEntry(sentimentScore: 0.6, createdAt: thisWeekDate(dayOffset: 2)),
            makeEntry(sentimentScore: -0.6, createdAt: thisWeekDate(dayOffset: 3)),
            makeEntry(sentimentScore: -0.7, createdAt: thisWeekDate(dayOffset: 4)),
            makeEntry(sentimentScore: -0.8, createdAt: thisWeekDate(dayOffset: 5)),
        ]
        let recap = RecapGenerator.weeklyRecap(entries: entries, weekOf: Date())
        XCTAssertEqual(recap.moodTrend, .declining)
        XCTAssertFalse(recap.challenges.isEmpty, "sentimentScore < -0.3 should populate challenges")
        XCTAssertFalse(recap.actionItem.isEmpty)
        // stable recap with no theme should produce a different actionItem
        let stableRecap = RecapGenerator.weeklyRecap(
            entries: (0..<5).map { i in makeEntry(sentimentScore: 0.05, createdAt: thisWeekDate(dayOffset: i)) },
            weekOf: Date()
        )
        XCTAssertNotEqual(recap.actionItem, stableRecap.actionItem,
                          "declining+challenges should hit the declining action path, not default")
    }

    func testActionItemWorkThemeDiffersFromDefault() {
        let workTag = Tag(name: "work")
        let workEntries = (0..<5).map { i -> JournalEntry in
            let e = makeEntry(sentimentScore: 0.05, createdAt: thisWeekDate(dayOffset: i))
            e.tags = [workTag]
            return e
        }
        let noThemeEntries = (0..<5).map { i in
            makeEntry(sentimentScore: 0.05, createdAt: thisWeekDate(dayOffset: i))
        }
        let workRecap = RecapGenerator.weeklyRecap(entries: workEntries, weekOf: Date())
        let defaultRecap = RecapGenerator.weeklyRecap(entries: noThemeEntries, weekOf: Date())
        XCTAssertFalse(workRecap.actionItem.isEmpty)
        XCTAssertNotEqual(workRecap.actionItem, defaultRecap.actionItem,
                          "work theme should hit the work action path")
    }

    func testActionItemSelfDoubtThemeDiffersFromWork() {
        let selfDoubtTag = Tag(name: "self-doubt")
        let selfDoubtEntries = (0..<5).map { i -> JournalEntry in
            let e = makeEntry(sentimentScore: 0.05, createdAt: thisWeekDate(dayOffset: i))
            e.tags = [selfDoubtTag]
            return e
        }
        let workTag = Tag(name: "work")
        let workEntries = (0..<5).map { i -> JournalEntry in
            let e = makeEntry(sentimentScore: 0.05, createdAt: thisWeekDate(dayOffset: i))
            e.tags = [workTag]
            return e
        }
        let selfDoubtRecap = RecapGenerator.weeklyRecap(entries: selfDoubtEntries, weekOf: Date())
        let workRecap = RecapGenerator.weeklyRecap(entries: workEntries, weekOf: Date())
        XCTAssertFalse(selfDoubtRecap.actionItem.isEmpty)
        XCTAssertNotEqual(selfDoubtRecap.actionItem, workRecap.actionItem,
                          "self-doubt tag should hit the self-doubt action path")
    }

    func testActionItemDefaultNoThemeNoDecline() {
        // No tags, stable trend → default path
        let entries = (0..<5).map { i in
            makeEntry(sentimentScore: 0.05, createdAt: thisWeekDate(dayOffset: i))
        }
        let recap = RecapGenerator.weeklyRecap(entries: entries, weekOf: Date())
        XCTAssertEqual(recap.moodTrend, .stable)
        XCTAssertTrue(recap.topThemes.isEmpty, "no-tag entries should have empty topThemes")
        XCTAssertFalse(recap.actionItem.isEmpty, "default action path should still produce a non-empty string")
    }

    // MARK: - GrowthNote: improving / declining / insufficient / empty branches

    func testGrowthNoteImproving() {
        // First half negative, second half positive → .improving trend
        let entries = [
            makeEntry(sentimentScore: -0.5, createdAt: thisWeekDate(dayOffset: 0)),
            makeEntry(sentimentScore: -0.4, createdAt: thisWeekDate(dayOffset: 1)),
            makeEntry(sentimentScore: -0.3, createdAt: thisWeekDate(dayOffset: 2)),
            makeEntry(sentimentScore:  0.5, createdAt: thisWeekDate(dayOffset: 3)),
            makeEntry(sentimentScore:  0.6, createdAt: thisWeekDate(dayOffset: 4)),
            makeEntry(sentimentScore:  0.7, createdAt: thisWeekDate(dayOffset: 5)),
        ]
        let recap = RecapGenerator.weeklyRecap(entries: entries, weekOf: Date())
        XCTAssertEqual(recap.moodTrend, .improving)
        XCTAssertFalse(recap.growthNote.isEmpty, "improving trend should produce a non-empty growthNote")

        // Must differ from the stablePositive path
        let stableRecap = RecapGenerator.weeklyRecap(
            entries: (0..<5).map { i in makeEntry(mood: .great, sentimentScore: 0.05, createdAt: thisWeekDate(dayOffset: i)) },
            weekOf: Date()
        )
        XCTAssertNotEqual(recap.growthNote, stableRecap.growthNote, "improving growthNote should differ from stable")
    }

    func testGrowthNoteDeclining() {
        // First half positive, second half negative → .declining trend
        let entries = [
            makeEntry(sentimentScore:  0.6, createdAt: thisWeekDate(dayOffset: 0)),
            makeEntry(sentimentScore:  0.5, createdAt: thisWeekDate(dayOffset: 1)),
            makeEntry(sentimentScore:  0.4, createdAt: thisWeekDate(dayOffset: 2)),
            makeEntry(sentimentScore: -0.5, createdAt: thisWeekDate(dayOffset: 3)),
            makeEntry(sentimentScore: -0.6, createdAt: thisWeekDate(dayOffset: 4)),
            makeEntry(sentimentScore: -0.7, createdAt: thisWeekDate(dayOffset: 5)),
        ]
        let recap = RecapGenerator.weeklyRecap(entries: entries, weekOf: Date())
        XCTAssertEqual(recap.moodTrend, .declining)
        XCTAssertFalse(recap.growthNote.isEmpty, "declining trend should produce a non-empty growthNote")

        let improvingEntries = [
            makeEntry(sentimentScore: -0.5, createdAt: thisWeekDate(dayOffset: 0)),
            makeEntry(sentimentScore: -0.4, createdAt: thisWeekDate(dayOffset: 1)),
            makeEntry(sentimentScore: -0.3, createdAt: thisWeekDate(dayOffset: 2)),
            makeEntry(sentimentScore:  0.5, createdAt: thisWeekDate(dayOffset: 3)),
            makeEntry(sentimentScore:  0.6, createdAt: thisWeekDate(dayOffset: 4)),
            makeEntry(sentimentScore:  0.7, createdAt: thisWeekDate(dayOffset: 5)),
        ]
        let improvingRecap = RecapGenerator.weeklyRecap(entries: improvingEntries, weekOf: Date())
        XCTAssertNotEqual(recap.growthNote, improvingRecap.growthNote, "declining growthNote should differ from improving")
    }

    func testGrowthNoteInsufficientData() {
        // 2 entries with no sentimentScore → trend = .insufficient (< 3 sentiments)
        let entries = [
            makeEntry(content: "entry one", createdAt: thisWeekDate(dayOffset: 0)),
            makeEntry(content: "entry two", createdAt: thisWeekDate(dayOffset: 1)),
        ]
        let recap = RecapGenerator.weeklyRecap(entries: entries, weekOf: Date())
        XCTAssertEqual(recap.moodTrend, .insufficient, "2 entries without sentimentScore should give insufficient trend")
        XCTAssertFalse(recap.growthNote.isEmpty, "insufficient trend should produce a non-empty growthNote")
    }

    func testGrowthNoteEmptyEntries() {
        let recap = RecapGenerator.weeklyRecap(entries: [], weekOf: Date())
        XCTAssertEqual(recap.entryCount, 0)
        XCTAssertFalse(recap.growthNote.isEmpty, "entryCount == 0 should produce a non-empty growthNote (empty branch)")
    }

    // MARK: - streakDays

    func testWeeklyRecapStreakDaysConsecutive() {
        // 3 entries on consecutive days starting from the start of this week
        let entries = (0..<3).map { i in
            makeEntry(content: "day \(i)", createdAt: thisWeekDate(dayOffset: i))
        }
        let recap = RecapGenerator.weeklyRecap(entries: entries, weekOf: Date())
        XCTAssertEqual(recap.streakDays, 3, "3 consecutive days should produce streakDays == 3")
    }

    func testWeeklyRecapStreakDaysEmpty() {
        let recap = RecapGenerator.weeklyRecap(entries: [], weekOf: Date())
        XCTAssertEqual(recap.streakDays, 0, "No entries should produce streakDays == 0")
    }

    // MARK: - MoodTrend enum properties

    func testMoodTrendEmojiNonEmpty() {
        for trend in [RecapGenerator.MoodTrend.improving, .declining, .stable, .insufficient] {
            XCTAssertFalse(trend.emoji.isEmpty, "\(trend.rawValue) emoji should be non-empty")
        }
    }

    func testMoodTrendDisplayNameNonEmpty() {
        for trend in [RecapGenerator.MoodTrend.improving, .declining, .stable, .insufficient] {
            XCTAssertFalse(trend.displayName.isEmpty, "\(trend.rawValue) displayName should be non-empty")
        }
    }
}
