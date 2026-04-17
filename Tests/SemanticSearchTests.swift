import XCTest
@testable import Kinen

final class SemanticSearchTests: XCTestCase {

    // MARK: - Helpers

    private func makeEntry(content: String, mood: Mood? = nil, createdAt: Date = Date()) -> JournalEntry {
        JournalEntry(content: content, mood: mood, createdAt: createdAt)
    }

    private func daysAgo(_ n: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -n, to: Date())!
    }

    // MARK: - search() Edge Cases

    func testEmptyQueryReturnsEmpty() {
        let entries = [makeEntry(content: "beach trip")]
        let results = SemanticSearch.search(query: "", in: entries)
        XCTAssertTrue(results.isEmpty)
    }

    func testEmptyEntriesReturnsEmpty() {
        let results = SemanticSearch.search(query: "beach", in: [])
        XCTAssertTrue(results.isEmpty)
    }

    func testNoMatchingTermReturnsEmpty() {
        let entries = [makeEntry(content: "sunny day at the park")]
        let results = SemanticSearch.search(query: "zqlmwxyz", in: entries)
        XCTAssertTrue(results.isEmpty)
    }

    // MARK: - search() Keyword Matching

    func testSingleWordMatchFound() {
        let entries = [makeEntry(content: "had a great beach vacation")]
        let results = SemanticSearch.search(query: "beach", in: entries)
        XCTAssertFalse(results.isEmpty)
        XCTAssertGreaterThan(results[0].score, 0)
    }

    func testCaseInsensitiveMatch() {
        let entries = [makeEntry(content: "Beach Vacation Was Amazing")]
        let results = SemanticSearch.search(query: "beach", in: entries)
        XCTAssertFalse(results.isEmpty)
    }

    func testScoreNeverExceedsOne() {
        let entries = [makeEntry(content: "beach beach beach beach beach")]
        let results = SemanticSearch.search(query: "beach", in: entries)
        XCTAssertFalse(results.isEmpty)
        XCTAssertLessThanOrEqual(results[0].score, 1.0)
    }

    func testLimitRespected() {
        let entries = (0..<10).map { i in makeEntry(content: "beach trip day \(i)") }
        let results = SemanticSearch.search(query: "beach", in: entries, limit: 3)
        XCTAssertLessThanOrEqual(results.count, 3)
    }

    func testResultsOrderedByDescendingScore() {
        // "beach trip" query: entry with both words scores higher than entry with one
        let highMatch = makeEntry(content: "a lovely beach trip with family")
        let lowMatch = makeEntry(content: "the beach was crowded and sunny today")
        let results = SemanticSearch.search(query: "beach trip", in: [lowMatch, highMatch])
        XCTAssertEqual(results.count, 2)
        XCTAssertGreaterThanOrEqual(results[0].score, results[1].score)
        XCTAssertEqual(results[0].entry.id, highMatch.id)
    }

    func testTitleAlsoSearched() {
        let entry = JournalEntry(content: "Just a regular day", title: "Amazing Beach Sunrise", createdAt: Date())
        let results = SemanticSearch.search(query: "beach", in: [entry])
        XCTAssertFalse(results.isEmpty, "Title content should be included in keyword search")
    }

    func testMultiWordQueryPartialMatch() {
        // "coffee morning" — entry with only "coffee" should still match (partial)
        let entries = [makeEntry(content: "enjoyed a coffee while reading")]
        let results = SemanticSearch.search(query: "coffee morning", in: entries)
        XCTAssertFalse(results.isEmpty)
        // Score > 0 since "coffee" matches; exact value varies by search mode
        XCTAssertGreaterThan(results[0].score, 0)
        XCTAssertLessThanOrEqual(results[0].score, 1.0)
    }

    // MARK: - answerQuestion() Edge Cases

    func testAnswerQuestionEmptyEntriesReturnsNil() {
        XCTAssertNil(SemanticSearch.answerQuestion("What was my happiest day?", entries: []))
    }

    // MARK: - answerQuestion() Mood Extremes

    func testAnswerQuestionHappiestReturnsHighestMoodEntry() {
        let entries = [
            makeEntry(content: "Terrible day at work", mood: .terrible),
            makeEntry(content: "Great day at the park", mood: .great),
            makeEntry(content: "Just a neutral Tuesday", mood: .neutral)
        ]
        let answer = SemanticSearch.answerQuestion("What was my happiest day?", entries: entries)
        XCTAssertNotNil(answer)
        XCTAssertTrue(answer!.contains("Great day at the park"))
    }

    func testAnswerQuestionWorstReturnsLowestMoodEntry() {
        let entries = [
            makeEntry(content: "Terrible day at work", mood: .terrible),
            makeEntry(content: "Great day at the park", mood: .great)
        ]
        let answer = SemanticSearch.answerQuestion("What was my worst day?", entries: entries)
        XCTAssertNotNil(answer)
        XCTAssertTrue(answer!.contains("Terrible day at work"))
    }

    func testAnswerQuestionSaddestAlsoWorksForLowMood() {
        let entries = [
            makeEntry(content: "Cried all afternoon", mood: .terrible),
            makeEntry(content: "Productive work session", mood: .good)
        ]
        let answer = SemanticSearch.answerQuestion("When was I saddest?", entries: entries)
        XCTAssertNotNil(answer)
        XCTAssertTrue(answer!.contains("Cried all afternoon"))
    }

    func testAnswerQuestionMoodExtremeWithNoMoodEntriesReturnsNil() {
        let entries = [makeEntry(content: "No mood recorded today")]
        let answer = SemanticSearch.answerQuestion("What was my happiest day?", entries: entries)
        XCTAssertNil(answer)
    }

    // MARK: - answerQuestion() Time Scoping

    func testAnswerQuestionThisWeekOnlyConsidersRecentEntries() {
        let recent = makeEntry(content: "Recent great beach day", mood: .great, createdAt: daysAgo(2))
        let old = makeEntry(content: "Old great beach day", mood: .great, createdAt: daysAgo(20))
        let answer = SemanticSearch.answerQuestion("What was my best day this week?", entries: [recent, old])
        XCTAssertNotNil(answer)
        XCTAssertTrue(answer!.contains("Recent great beach day"))
        XCTAssertFalse(answer!.contains("Old great beach day"))
    }

    func testAnswerQuestionNoEntriesThisWeekReturnsNil() {
        let entries = [makeEntry(content: "Old entry", mood: .great, createdAt: daysAgo(14))]
        let answer = SemanticSearch.answerQuestion("happiest this week", entries: entries)
        XCTAssertNil(answer)
    }

    func testAnswerQuestionThisMonthExcludesOldEntries() {
        let recent = makeEntry(content: "Good month entry", mood: .great, createdAt: daysAgo(15))
        let old = makeEntry(content: "Old year entry", mood: .great, createdAt: daysAgo(90))
        let answer = SemanticSearch.answerQuestion("best day this month", entries: [recent, old])
        XCTAssertNotNil(answer)
        XCTAssertTrue(answer!.contains("Good month entry"))
    }

    // MARK: - answerQuestion() Topic Search

    func testAnswerQuestionTopicMatchFound() {
        let entries = [makeEntry(content: "a wonderful beach vacation")]
        let answer = SemanticSearch.answerQuestion("beach", entries: entries)
        // keyword score = 1.0 > 0.3 threshold, so result expected
        XCTAssertNotNil(answer)
    }

    func testAnswerQuestionTopicNoMatchReturnsNil() {
        let entries = [makeEntry(content: "sunny day at the park")]
        let answer = SemanticSearch.answerQuestion("xyzzyqmwn", entries: entries)
        XCTAssertNil(answer)
    }
}
