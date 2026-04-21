import XCTest
@testable import Kinen

final class MoodTests: XCTestCase {

    // MARK: - rawValue

    func testRawValueTerrible() { XCTAssertEqual(Mood.terrible.rawValue, 1) }
    func testRawValueBad() { XCTAssertEqual(Mood.bad.rawValue, 2) }
    func testRawValueNeutral() { XCTAssertEqual(Mood.neutral.rawValue, 3) }
    func testRawValueGood() { XCTAssertEqual(Mood.good.rawValue, 4) }
    func testRawValueGreat() { XCTAssertEqual(Mood.great.rawValue, 5) }

    // MARK: - Roundtrip via rawValue

    func testRawValueRoundtrip() {
        for mood in Mood.allCases {
            XCTAssertEqual(Mood(rawValue: mood.rawValue), mood)
        }
    }

    // MARK: - allCases

    func testAllCasesCount() {
        XCTAssertEqual(Mood.allCases.count, 5)
    }

    func testAllCasesAscendingRawValues() {
        let values = Mood.allCases.map(\.rawValue)
        XCTAssertEqual(values, [1, 2, 3, 4, 5])
    }

    // MARK: - normalizedValue

    func testNormalizedValueTerrible() {
        XCTAssertEqual(Mood.terrible.normalizedValue, 0.0, accuracy: 0.001)
    }

    func testNormalizedValueBad() {
        XCTAssertEqual(Mood.bad.normalizedValue, 0.25, accuracy: 0.001)
    }

    func testNormalizedValueNeutral() {
        XCTAssertEqual(Mood.neutral.normalizedValue, 0.5, accuracy: 0.001)
    }

    func testNormalizedValueGood() {
        XCTAssertEqual(Mood.good.normalizedValue, 0.75, accuracy: 0.001)
    }

    func testNormalizedValueGreat() {
        XCTAssertEqual(Mood.great.normalizedValue, 1.0, accuracy: 0.001)
    }

    func testNormalizedValueRange() {
        for mood in Mood.allCases {
            XCTAssertGreaterThanOrEqual(mood.normalizedValue, 0.0)
            XCTAssertLessThanOrEqual(mood.normalizedValue, 1.0)
        }
    }

    // MARK: - emoji

    func testEmojiTerrible() { XCTAssertEqual(Mood.terrible.emoji, "😢") }
    func testEmojiBad() { XCTAssertEqual(Mood.bad.emoji, "😔") }
    func testEmojiNeutral() { XCTAssertEqual(Mood.neutral.emoji, "😐") }
    func testEmojiGood() { XCTAssertEqual(Mood.good.emoji, "😊") }
    func testEmojiGreat() { XCTAssertEqual(Mood.great.emoji, "🤩") }

    func testAllEmojisNonEmpty() {
        for mood in Mood.allCases {
            XCTAssertFalse(mood.emoji.isEmpty, "\(mood) emoji should not be empty")
        }
    }

    // MARK: - id

    func testIdMatchesRawValue() {
        for mood in Mood.allCases {
            XCTAssertEqual(mood.id, mood.rawValue)
        }
    }

    // MARK: - label

    func testAllLabelsNonEmpty() {
        for mood in Mood.allCases {
            XCTAssertFalse(mood.label.isEmpty, "\(mood) label should not be empty")
        }
    }

    func testAllLabelsDistinct() {
        let labels = Mood.allCases.map(\.label)
        XCTAssertEqual(Set(labels).count, labels.count, "Each mood should have a unique label")
    }
}
