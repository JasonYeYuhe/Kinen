import XCTest
@testable import Kinen

final class WritingSessionTests: XCTestCase {

    // MARK: - wordsWritten

    func testWordsWrittenZeroOnFreshSession() {
        let session = WritingSession(entryId: nil, initialWordCount: 10)
        XCTAssertEqual(session.wordsWritten, 0, "No words written yet — initial == final")
    }

    func testWordsWrittenPositiveDelta() {
        let session = WritingSession(entryId: nil, initialWordCount: 10)
        session.finalWordCount = 25
        XCTAssertEqual(session.wordsWritten, 15)
    }

    func testWordsWrittenNeverNegative() {
        let session = WritingSession(entryId: nil, initialWordCount: 20)
        session.finalWordCount = 5
        XCTAssertEqual(session.wordsWritten, 0, "max(0, …) guards against negative delta")
    }

    func testWordsWrittenWithZeroInitial() {
        let session = WritingSession(entryId: nil, initialWordCount: 0)
        session.finalWordCount = 42
        XCTAssertEqual(session.wordsWritten, 42)
    }

    func testWordsWrittenIdenticalCounts() {
        let session = WritingSession(entryId: nil, initialWordCount: 7)
        // finalWordCount defaults to initialWordCount in init
        XCTAssertEqual(session.finalWordCount, 7)
        XCTAssertEqual(session.wordsWritten, 0)
    }

    // MARK: - formattedDuration

    private func makeSession(seconds: TimeInterval) -> WritingSession {
        let session = WritingSession()
        let now = Date()
        session.startedAt = now.addingTimeInterval(-seconds)
        session.endedAt = now
        return session
    }

    func testFormattedDurationSecondsOnly() {
        let session = makeSession(seconds: 45)
        XCTAssertEqual(session.formattedDuration, "45s")
    }

    func testFormattedDurationZeroSeconds() {
        let session = makeSession(seconds: 0)
        XCTAssertEqual(session.formattedDuration, "0s")
    }

    func testFormattedDurationExactlyOneMinute() {
        let session = makeSession(seconds: 60)
        XCTAssertEqual(session.formattedDuration, "1m 0s")
    }

    func testFormattedDurationMinutesAndSeconds() {
        let session = makeSession(seconds: 210) // 3m 30s
        XCTAssertEqual(session.formattedDuration, "3m 30s")
    }

    func testFormattedDurationLargeValue() {
        let session = makeSession(seconds: 3661) // 61m 1s
        XCTAssertEqual(session.formattedDuration, "61m 1s")
    }

    func testFormattedDurationFiftyNineSeconds() {
        let session = makeSession(seconds: 59)
        XCTAssertEqual(session.formattedDuration, "59s")
    }

    // MARK: - finish()

    func testFinishSetsFinalWordCount() {
        let session = WritingSession(entryId: nil, initialWordCount: 5)
        session.finish(wordCount: 20)
        XCTAssertEqual(session.finalWordCount, 20)
    }

    func testFinishSetsEndedAt() {
        let session = WritingSession(entryId: nil, initialWordCount: 0)
        XCTAssertNil(session.endedAt)
        session.finish(wordCount: 10)
        XCTAssertNotNil(session.endedAt)
    }

    func testFinishEndedAtIsRecent() {
        let session = WritingSession(entryId: nil, initialWordCount: 0)
        session.finish(wordCount: 10)
        let elapsed = abs(session.endedAt!.timeIntervalSinceNow)
        XCTAssertLessThan(elapsed, 2, "endedAt should be within 2 seconds of now")
    }

    func testFinishPreservesInitialWordCount() {
        let session = WritingSession(entryId: nil, initialWordCount: 15)
        session.finish(wordCount: 30)
        XCTAssertEqual(session.initialWordCount, 15)
        XCTAssertEqual(session.wordsWritten, 15)
    }

    func testFinishWithSameWordCountGivesZeroWordsWritten() {
        let session = WritingSession(entryId: nil, initialWordCount: 10)
        session.finish(wordCount: 10)
        XCTAssertEqual(session.wordsWritten, 0)
    }

    // MARK: - duration

    func testDurationWithEndedAtSet() {
        let session = WritingSession()
        let past = Date().addingTimeInterval(-120)
        session.startedAt = past
        session.endedAt = Date()
        XCTAssertEqual(session.duration, 120, accuracy: 1.0)
    }

    func testDurationWithoutEndedAtUsesNow() {
        let session = WritingSession()
        session.startedAt = Date().addingTimeInterval(-30)
        // endedAt is nil → uses Date()
        XCTAssertEqual(session.duration, 30, accuracy: 2.0)
    }

    // MARK: - entryId

    func testEntryIdNilByDefault() {
        let session = WritingSession()
        XCTAssertNil(session.entryId)
    }

    func testEntryIdStoredCorrectly() {
        let id = UUID()
        let session = WritingSession(entryId: id)
        XCTAssertEqual(session.entryId, id)
    }
}
