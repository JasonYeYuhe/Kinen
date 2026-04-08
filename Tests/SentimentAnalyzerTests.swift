import XCTest
@testable import Kinen

final class SentimentAnalyzerTests: XCTestCase {
    let analyzer = SentimentAnalyzer.shared

    func testPositiveSentiment() async {
        let score = await analyzer.analyzeSentiment("I had an amazing day! Everything went perfectly and I feel so happy.")
        XCTAssertGreaterThan(score, 0, "Positive text should have positive sentiment")
    }

    func testNegativeSentiment() async {
        let score = await analyzer.analyzeSentiment("Today was terrible. Nothing went right and I feel awful.")
        XCTAssertLessThan(score, 0, "Negative text should have negative sentiment")
    }

    func testTopicExtraction() async {
        let topics = await analyzer.extractTopics("I went to Tokyo with Sarah and visited the famous Shibuya crossing. The sushi restaurant was excellent.")
        XCTAssertFalse(topics.isEmpty, "Should extract at least some topics")
    }

    func testEmptyText() async {
        let score = await analyzer.analyzeSentiment("")
        XCTAssertEqual(score, 0.0, "Empty text should return neutral")
    }

    func testMoodValues() {
        XCTAssertEqual(Mood.terrible.rawValue, 1)
        XCTAssertEqual(Mood.great.rawValue, 5)
        XCTAssertEqual(Mood.allCases.count, 5)
    }
}
