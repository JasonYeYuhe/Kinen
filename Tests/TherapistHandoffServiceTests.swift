import XCTest
@testable import Kinen

final class TherapistHandoffServiceTests: XCTestCase {

    // MARK: - Helpers

    /// Build an entry with explicit createdAt + mood + sentiment (no SwiftData context required).
    private func entry(
        days daysAgo: Int,
        mood: Mood? = nil,
        sentiment: Double? = nil,
        content: String = "Sample journal entry content for testing.",
        title: String? = nil,
        pinned: Bool = false
    ) -> JournalEntry {
        let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
        let e = JournalEntry(content: content, title: title, mood: mood, createdAt: date)
        e.sentimentScore = sentiment
        e.isPinned = pinned
        return e
    }

    private func range(daysBack: Int) -> HandoffReport.DateRange {
        let now = Date()
        let start = Calendar.current.date(byAdding: .day, value: -daysBack, to: now) ?? now
        return HandoffReport.DateRange(start: start, end: now)
    }

    // MARK: - Range filtering

    func testEntriesOutsideRangeAreIgnored() {
        let inside = entry(days: 3, mood: .good)
        let outside = entry(days: 30, mood: .terrible)

        let report = TherapistHandoffService.buildReport(
            from: [inside, outside],
            range: range(daysBack: 7)
        )

        XCTAssertEqual(report.overview.totalEntries, 1)
        XCTAssertEqual(report.moodTrend.count, 1)
        XCTAssertEqual(report.moodTrend.first?.mood, Mood.good.rawValue)
    }

    func testEmptyRangeReturnsEmptyOverview() {
        let report = TherapistHandoffService.buildReport(
            from: [],
            range: range(daysBack: 7)
        )

        XCTAssertEqual(report.overview.totalEntries, 0)
        XCTAssertNil(report.overview.averageMood)
        XCTAssertNil(report.overview.averageSentiment)
        XCTAssertTrue(report.topThemes.isEmpty)
        XCTAssertTrue(report.cognitiveDistortions.isEmpty)
    }

    // MARK: - Overview

    func testAverageMoodCalculation() throws {
        let entries = [
            entry(days: 1, mood: .great),    // 5
            entry(days: 2, mood: .neutral),  // 3
            entry(days: 3, mood: .terrible)  // 1
        ]
        let overview = TherapistHandoffService.buildOverview(entries)

        XCTAssertEqual(overview.totalEntries, 3)
        XCTAssertEqual(try XCTUnwrap(overview.averageMood), 3.0, accuracy: 0.01)
    }

    func testAverageMoodIgnoresEntriesWithoutMood() throws {
        let entries = [
            entry(days: 1, mood: .great),
            entry(days: 2, mood: nil),  // skipped
            entry(days: 3, mood: .neutral)
        ]
        let overview = TherapistHandoffService.buildOverview(entries)

        XCTAssertEqual(try XCTUnwrap(overview.averageMood), 4.0, accuracy: 0.01)
    }

    func testHighestAndLowestMoodDays() {
        let great = entry(days: 1, mood: .great)
        let terrible = entry(days: 5, mood: .terrible)
        let entries = [great, entry(days: 3, mood: .neutral), terrible]

        let overview = TherapistHandoffService.buildOverview(entries)
        XCTAssertEqual(overview.highestMoodDay, great.createdAt)
        XCTAssertEqual(overview.lowestMoodDay, terrible.createdAt)
    }

    func testWritingDaysCountsUniqueDays() {
        // 3 entries on the same day, 1 entry on another day → 2 writing days
        let cal = Calendar.current
        let day1 = cal.startOfDay(for: Date())
        let day2 = cal.date(byAdding: .day, value: -2, to: day1) ?? day1

        let entries = [
            JournalEntry(content: "a", createdAt: day1.addingTimeInterval(3600)),
            JournalEntry(content: "b", createdAt: day1.addingTimeInterval(7200)),
            JournalEntry(content: "c", createdAt: day1.addingTimeInterval(10800)),
            JournalEntry(content: "d", createdAt: day2.addingTimeInterval(3600))
        ]
        let overview = TherapistHandoffService.buildOverview(entries)
        XCTAssertEqual(overview.writingDays, 2)
    }

    func testLongestSilenceIsLargestGap() {
        let cal = Calendar.current
        let now = Date()
        let entries = [
            JournalEntry(content: "a", createdAt: cal.date(byAdding: .day, value: -30, to: now)!),
            JournalEntry(content: "b", createdAt: cal.date(byAdding: .day, value: -25, to: now)!),  // 5d gap
            JournalEntry(content: "c", createdAt: cal.date(byAdding: .day, value: -10, to: now)!),  // 15d gap
            JournalEntry(content: "d", createdAt: cal.date(byAdding: .day, value: -8, to: now)!)    // 2d gap
        ]
        let overview = TherapistHandoffService.buildOverview(entries)
        XCTAssertEqual(overview.longestSilence, 15)
    }

    // MARK: - Themes

    func testThemesAggregateTagFrequencies() {
        let work = Tag(name: "work")
        let family = Tag(name: "family")

        let e1 = entry(days: 1)
        e1.tags = [work, family]
        let e2 = entry(days: 2)
        e2.tags = [work]
        let e3 = entry(days: 3)
        e3.tags = [work]

        let themes = TherapistHandoffService.buildThemes([e1, e2, e3])
        XCTAssertEqual(themes.count, 2)
        XCTAssertEqual(themes.first?.name, "work")
        XCTAssertEqual(themes.first?.count, 3)
        XCTAssertEqual(themes.last?.name, "family")
        XCTAssertEqual(themes.last?.count, 1)
    }

    func testThemesAreCappedByLimit() {
        let entries = (1...10).map { i -> JournalEntry in
            let e = entry(days: i)
            e.tags = [Tag(name: "tag\(i)")]
            return e
        }
        let themes = TherapistHandoffService.buildThemes(entries, limit: 3)
        XCTAssertEqual(themes.count, 3)
    }

    // MARK: - Distortions

    func testDistortionDetectionInTherapistContext() {
        let catastrophic = entry(days: 1, content: "This is the worst thing ever, my life is ruined.")
        let neutral = entry(days: 2, content: "Had coffee with a friend. Nice day.")

        let stats = TherapistHandoffService.buildDistortions([catastrophic, neutral])
        XCTAssertTrue(stats.contains { $0.name == "Catastrophizing" })
    }

    func testDistortionsCountedOncePerEntry() {
        // Multiple catastrophizing triggers in a single entry should count as 1 entry, not many.
        let multi = entry(days: 1, content: "It was terrible, the worst day, a complete disaster, I feel hopeless.")
        let stats = TherapistHandoffService.buildDistortions([multi])
        if let cat = stats.first(where: { $0.name == "Catastrophizing" }) {
            XCTAssertEqual(cat.count, 1, "Each distortion should count once per entry, not per trigger word")
        } else {
            XCTFail("Expected to find Catastrophizing distortion")
        }
    }

    // MARK: - Highlights

    func testHighlightsIncludePinnedEntries() {
        let pinned = entry(days: 5, mood: .neutral, content: "Pinned thought.", pinned: true)
        let normal = entry(days: 3, mood: .good, content: "Just a normal entry.")

        let highlights = TherapistHandoffService.buildHighlights([pinned, normal])
        XCTAssertTrue(highlights.contains { $0.reason == .userPinned })
    }

    func testHighlightsIncludeHighestAndLowestMood() {
        let entries = [
            entry(days: 1, mood: .great, content: "Best day"),
            entry(days: 2, mood: .neutral, content: "Meh day"),
            entry(days: 3, mood: .terrible, content: "Worst day")
        ]
        let highlights = TherapistHandoffService.buildHighlights(entries)
        XCTAssertTrue(highlights.contains { $0.reason == .highestMood })
        XCTAssertTrue(highlights.contains { $0.reason == .lowestMood })
    }

    func testHighlightsAreCappedAtLimit() {
        let entries = (1...10).map { i in
            entry(days: i, mood: i % 2 == 0 ? .great : .terrible, sentiment: Double(i) * 0.1, pinned: i <= 3)
        }
        let highlights = TherapistHandoffService.buildHighlights(entries, limit: 4)
        XCTAssertLessThanOrEqual(highlights.count, 4)
    }

    func testHighlightsDeduplicate() {
        // Pin the highest-mood entry → it should appear only once even though it qualifies twice.
        let only = entry(days: 1, mood: .great, content: "Both pinned and highest", pinned: true)
        let highlights = TherapistHandoffService.buildHighlights([only])
        XCTAssertEqual(highlights.count, 1)
    }

    // MARK: - Crisis

    func testCrisisFlagsAreDetected() {
        let crisis = entry(days: 1, content: "I want to die. There's no point anymore.")
        let safe = entry(days: 2, content: "Had a quiet morning, made some tea.")

        let flags = TherapistHandoffService.buildCrisisFlags([crisis, safe])
        XCTAssertEqual(flags.count, 1)
        XCTAssertEqual(flags.first?.severity, "high")
    }

    // MARK: - Snippet sanitization

    func testSnippetStripsTemplateMarkers() {
        let raw = "<!-- gratitude-1 -->\n**Three things I'm grateful for**\nMy family, the sunshine, hot coffee."
        let snippet = TherapistHandoffService.snippet(from: raw)
        XCTAssertFalse(snippet.contains("<!--"))
        XCTAssertFalse(snippet.contains("**"))
        XCTAssertTrue(snippet.contains("My family"))
    }

    func testSnippetTruncatesLongContent() {
        let long = String(repeating: "word ", count: 200)
        let snippet = TherapistHandoffService.snippet(from: long, length: 100)
        XCTAssertTrue(snippet.hasSuffix("…"))
        XCTAssertLessThanOrEqual(snippet.count, 101) // 100 chars + ellipsis
    }

    func testSnippetCollapsesWhitespace() {
        let messy = "Hello\n\n\nworld    with     gaps"
        let snippet = TherapistHandoffService.snippet(from: messy)
        XCTAssertEqual(snippet, "Hello world with gaps")
    }

    // MARK: - Markdown rendering

    func testMarkdownContainsSectionHeaders() {
        let entries = [
            entry(days: 1, mood: .good, content: "Productive morning."),
            entry(days: 2, mood: .terrible, content: "Disaster day, everything ruined.")
        ]
        let report = TherapistHandoffService.buildReport(
            from: entries,
            range: range(daysBack: 7),
            userTopics: "Work-life balance"
        )
        let md = TherapistHandoffService.renderMarkdown(report)

        XCTAssertTrue(md.contains("# Therapist Handoff"))
        XCTAssertTrue(md.contains("## Overview"))
        XCTAssertTrue(md.contains("Work-life balance"))
    }

    func testMarkdownOmitsEmptySections() {
        let report = TherapistHandoffService.buildReport(
            from: [],
            range: range(daysBack: 7)
        )
        let md = TherapistHandoffService.renderMarkdown(report)

        XCTAssertFalse(md.contains("## Overview"))
        XCTAssertFalse(md.contains("## Recurring themes"))
        XCTAssertFalse(md.contains("## Selected entries"))
    }

    // MARK: - Section opt-out

    func testDisablingThemesProducesEmptyThemes() {
        let work = Tag(name: "work")
        let e = entry(days: 1, mood: .good)
        e.tags = [work]

        var sections = HandoffReport.Sections.all
        sections.topThemes = false

        let report = TherapistHandoffService.buildReport(
            from: [e],
            range: range(daysBack: 7),
            sections: sections
        )
        XCTAssertTrue(report.topThemes.isEmpty)
        // But mood data should still be present
        XCTAssertEqual(report.moodTrend.count, 1)
    }

    // MARK: - Markdown: crisis section

    func testMarkdownIncludesCrisisSection() {
        let crisis = entry(days: 1, content: "I want to end my life. There is no reason to keep going.")
        let report = TherapistHandoffService.buildReport(
            from: [crisis],
            range: range(daysBack: 7)
        )
        let md = TherapistHandoffService.renderMarkdown(report)
        XCTAssertTrue(md.contains("Concerning passages"), "Crisis entry should produce the '⚠️ Concerning passages' section")
        XCTAssertTrue(md.contains("high"), "High-severity crisis should appear in markdown")
    }

    // MARK: - Markdown: cognitive distortions with example sentence

    func testMarkdownIncludesCognitivePatternsWithExample() {
        let catastrophic = entry(days: 1, content: "Everything is ruined. This is the worst disaster of my entire life.")
        let report = TherapistHandoffService.buildReport(
            from: [catastrophic],
            range: range(daysBack: 7)
        )
        let md = TherapistHandoffService.renderMarkdown(report)
        XCTAssertTrue(md.contains("Cognitive patterns"), "Distortion in entry should produce the cognitive patterns section")
        // renderMarkdown formats example sentences with "> " (blockquote)
        XCTAssertTrue(md.contains(">"), "Distortion example should be rendered as a blockquote")
    }

    // MARK: - Markdown: selected entries section

    func testMarkdownIncludesSelectedEntriesSection() {
        let entries = [
            entry(days: 1, mood: .great, content: "Best morning run."),
            entry(days: 3, mood: .terrible, content: "Exhausting work meeting."),
        ]
        let report = TherapistHandoffService.buildReport(
            from: entries,
            range: range(daysBack: 7)
        )
        let md = TherapistHandoffService.renderMarkdown(report)
        XCTAssertTrue(md.contains("Selected entries"), "Report with mood entries should render '## Selected entries' section")
    }

    // MARK: - buildHighlights: largestDeviation from sentiment-only entries

    func testHighlightsLargestDeviationFromSentimentOnlyEntries() {
        // 3 entries with sentiment scores, no mood, not pinned
        // avg = (0.9 + 0.1 + 0.5) / 3 = 0.5
        // deviations: |0.9−0.5|=0.4, |0.1−0.5|=0.4, |0.5−0.5|=0.0
        // top-2 by deviation are the 0.9 and 0.1 entries
        let high = entry(days: 1, mood: nil, content: "Wonderful joyful day")
        high.sentimentScore = 0.9
        let low = entry(days: 2, mood: nil, content: "Terrible sad afternoon")
        low.sentimentScore = 0.1
        let mid = entry(days: 3, mood: nil, content: "Ordinary Tuesday")
        mid.sentimentScore = 0.5

        let highlights = TherapistHandoffService.buildHighlights([high, low, mid])
        XCTAssertFalse(highlights.isEmpty, "Entries with sentiment scores should produce highlights via largestDeviation")
        XCTAssertTrue(highlights.allSatisfy { $0.reason == .largestDeviation },
                      "All highlights should have .largestDeviation reason when entries have no mood and are not pinned")
        XCTAssertEqual(highlights.count, 2, "Top-2 deviation entries should be returned")
    }

    // MARK: - buildOverview: longestSilence for single entry

    func testOverviewLongestSilenceZeroForSingleEntry() {
        let sole = entry(days: 5)
        let overview = TherapistHandoffService.buildOverview([sole])
        XCTAssertEqual(overview.longestSilence, 0,
                       "A single entry has no gap to measure — longestSilence should be 0")
        XCTAssertEqual(overview.totalEntries, 1)
    }
}
