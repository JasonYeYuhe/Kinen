import XCTest
@testable import Kinen

final class JournalModelTests: XCTestCase {

    // MARK: - Journal init

    func testInitDefaultProperties() {
        let journal = Journal(name: "Personal")
        XCTAssertEqual(journal.name, "Personal")
        XCTAssertEqual(journal.icon, "book.closed")
        XCTAssertEqual(journal.colorHex, "8B5CF6")
        XCTAssertFalse(journal.isDefault)
        XCTAssertNotNil(journal.id)
        XCTAssert(abs(journal.createdAt.timeIntervalSinceNow) < 5)
    }

    func testInitCustomProperties() {
        let journal = Journal(name: "Work", icon: "briefcase.fill", colorHex: "3B82F6", isDefault: true)
        XCTAssertEqual(journal.name, "Work")
        XCTAssertEqual(journal.icon, "briefcase.fill")
        XCTAssertEqual(journal.colorHex, "3B82F6")
        XCTAssertTrue(journal.isDefault)
    }

    func testEachJournalGetsUniqueId() {
        let a = Journal(name: "A")
        let b = Journal(name: "B")
        XCTAssertNotEqual(a.id, b.id)
    }

    // MARK: - safeEntries + entryCount

    func testSafeEntriesReturnsEmptyWhenNil() {
        let journal = Journal(name: "Test")
        journal.entries = nil
        XCTAssertEqual(journal.safeEntries.count, 0)
    }

    func testSafeEntriesReturnsEmptyArrayFromInit() {
        let journal = Journal(name: "Test")
        XCTAssertEqual(journal.safeEntries.count, 0)
    }

    func testEntryCountReflectsSafeEntries() {
        let journal = Journal(name: "Test")
        XCTAssertEqual(journal.entryCount, 0)
    }

    func testEntryCountWhenEntriesNil() {
        let journal = Journal(name: "Test")
        journal.entries = nil
        XCTAssertEqual(journal.entryCount, 0)
    }

    // MARK: - presets

    func testPresetsCount() {
        XCTAssertEqual(Journal.presets.count, 6)
    }

    func testPresetsHaveUniqueNames() {
        let names = Journal.presets.map(\.name)
        XCTAssertEqual(names.count, Set(names).count, "All preset names should be unique")
    }

    func testPresetsHaveUniqueIcons() {
        let icons = Journal.presets.map(\.icon)
        XCTAssertEqual(icons.count, Set(icons).count, "All preset icons should be unique")
    }

    func testPresetsHaveNonEmptyFields() {
        for preset in Journal.presets {
            XCTAssertFalse(preset.name.isEmpty, "Preset name should not be empty")
            XCTAssertFalse(preset.icon.isEmpty, "Preset icon should not be empty")
            XCTAssertFalse(preset.color.isEmpty, "Preset color should not be empty")
        }
    }

    func testPresetsColorsAreValidHex() {
        for preset in Journal.presets {
            XCTAssertEqual(preset.color.count, 6, "Preset color should be 6-char hex: \(preset.color)")
        }
    }

    func testPresetsContainsExpectedJournalTypes() {
        let names = Set(Journal.presets.map(\.name))
        XCTAssertTrue(names.contains("Personal"))
        XCTAssertTrue(names.contains("Work"))
        XCTAssertTrue(names.contains("Travel"))
    }
}

// MARK: -

final class InsightTypeTests: XCTestCase {

    private let allCases: [InsightType] = [
        .sentiment, .pattern, .suggestion, .topicExtraction, .streak
    ]

    func testCasesCount() {
        XCTAssertEqual(allCases.count, 5)
    }

    func testRawValueRoundtrip() {
        for type in allCases {
            XCTAssertEqual(InsightType(rawValue: type.rawValue), type)
        }
    }

    func testExpectedRawValues() {
        XCTAssertEqual(InsightType.sentiment.rawValue, "sentiment")
        XCTAssertEqual(InsightType.pattern.rawValue, "pattern")
        XCTAssertEqual(InsightType.suggestion.rawValue, "suggestion")
        XCTAssertEqual(InsightType.topicExtraction.rawValue, "topicExtraction")
        XCTAssertEqual(InsightType.streak.rawValue, "streak")
    }

    func testUnknownRawValueReturnsNil() {
        XCTAssertNil(InsightType(rawValue: "nonexistent"))
    }
}

// MARK: -

final class HandoffReportTests: XCTestCase {

    // MARK: - DateRange.dayCount

    func testDayCountSameDayIsOne() {
        let now = Date()
        let range = HandoffReport.DateRange(start: now, end: now)
        XCTAssertEqual(range.dayCount, 1)
    }

    func testDayCountSevenDays() {
        let end = Date()
        let start = Calendar.current.date(byAdding: .day, value: -6, to: end)!
        let range = HandoffReport.DateRange(start: start, end: end)
        XCTAssertEqual(range.dayCount, 6)
    }

    func testDayCountThirtyDays() {
        let end = Date()
        let start = Calendar.current.date(byAdding: .day, value: -30, to: end)!
        let range = HandoffReport.DateRange(start: start, end: end)
        XCTAssertEqual(range.dayCount, 30)
    }

    func testDayCountNeverBelowOne() {
        // End before start should still return ≥ 1
        let now = Date()
        let past = Calendar.current.date(byAdding: .day, value: -1, to: now)!
        let range = HandoffReport.DateRange(start: now, end: past) // reversed
        XCTAssertGreaterThanOrEqual(range.dayCount, 1)
    }

    // MARK: - Sections defaults

    func testSectionsDefaultsAllTrue() {
        let sections = HandoffReport.Sections()
        XCTAssertTrue(sections.overview)
        XCTAssertTrue(sections.moodTrend)
        XCTAssertTrue(sections.topThemes)
        XCTAssertTrue(sections.cognitiveDistortions)
        XCTAssertTrue(sections.highlightedEntries)
        XCTAssertTrue(sections.crisisFlags)
        XCTAssertTrue(sections.userTopics)
    }

    func testSectionsAllStaticEqualsDefault() {
        XCTAssertEqual(HandoffReport.Sections.all, HandoffReport.Sections())
    }

    func testSectionsCanDisableIndividually() {
        var sections = HandoffReport.Sections.all
        sections.overview = false
        sections.crisisFlags = false
        XCTAssertFalse(sections.overview)
        XCTAssertFalse(sections.crisisFlags)
        XCTAssertTrue(sections.moodTrend, "Other sections should remain enabled")
    }

    // MARK: - HighlightReason rawValue

    func testHighlightReasonRawValues() {
        XCTAssertEqual(HandoffReport.HighlightedEntry.HighlightReason.lowestMood.rawValue, "lowestMood")
        XCTAssertEqual(HandoffReport.HighlightedEntry.HighlightReason.highestMood.rawValue, "highestMood")
        XCTAssertEqual(HandoffReport.HighlightedEntry.HighlightReason.largestDeviation.rawValue, "largestDeviation")
        XCTAssertEqual(HandoffReport.HighlightedEntry.HighlightReason.crisis.rawValue, "crisis")
        XCTAssertEqual(HandoffReport.HighlightedEntry.HighlightReason.userPinned.rawValue, "userPinned")
    }

    func testHighlightReasonRoundtrip() {
        let reasons: [HandoffReport.HighlightedEntry.HighlightReason] = [
            .lowestMood, .highestMood, .largestDeviation, .crisis, .userPinned
        ]
        for reason in reasons {
            XCTAssertEqual(HandoffReport.HighlightedEntry.HighlightReason(rawValue: reason.rawValue), reason)
        }
    }
}
