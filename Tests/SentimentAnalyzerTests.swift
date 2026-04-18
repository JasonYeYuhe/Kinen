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

    // MARK: - Sentiment score range and neutral text

    func testSentimentScoreInValidRange() async {
        // Any text must return a score that NL can produce: [-1.0, 1.0]
        let texts = [
            "I love everything about today! This is absolutely wonderful and the best day ever!",
            "I feel somewhat okay about things.",
            "Numbers: 1 2 3 4 5 6 7 8 9 10."
        ]
        for text in texts {
            let score = await analyzer.analyzeSentiment(text)
            XCTAssertGreaterThanOrEqual(score, -1.0, "Score must be >= -1.0 for: \(text)")
            XCTAssertLessThanOrEqual(score, 1.0, "Score must be <= 1.0 for: \(text)")
        }
    }

    // MARK: - extractTopics edge cases

    func testExtractTopicsEmpty() async {
        let topics = await analyzer.extractTopics("")
        XCTAssertTrue(topics.isEmpty, "Empty text should return no topics")
    }

    func testExtractTopicsShortWordsFiltered() async {
        // "a", "an", "it" are < 3 chars — should be filtered from noun path (> 3 check)
        // and entity path (> 2 check means "a", "it" filtered, "an" filtered)
        let topics = await analyzer.extractTopics("A it an go to.")
        for topic in topics {
            XCTAssertGreaterThan(topic.count, 2, "Topics shorter than 3 chars should be filtered: '\(topic)'")
        }
    }

    func testStopWordsNotIncluded() async {
        // Verify that known stop words do not appear in topic results
        let stopWords: Set<String> = ["thing", "time", "today", "something", "someone", "nothing", "everything", "year", "month", "week"]
        let text = "I did something with everyone today. The thing about time is that year after year and month after month everything changes."
        let topics = await analyzer.extractTopics(text)
        for topic in topics {
            XCTAssertFalse(stopWords.contains(topic), "Stop word '\(topic)' should be filtered from topics")
        }
    }

    func testExtractTopicsWithProperName() async {
        let topics = await analyzer.extractTopics("I had lunch with Jennifer in Chicago at the famous restaurant.")
        // NL entity recognition should pick up person/place names
        XCTAssertFalse(topics.isEmpty, "Named entity text should produce at least one topic")
    }

    func testExtractTopicsReturnsLowercased() async {
        let topics = await analyzer.extractTopics("Alice went to Paris for a conference about Technology.")
        for topic in topics {
            XCTAssertEqual(topic, topic.lowercased(), "All topics should be lowercased: '\(topic)'")
        }
    }

    func testExtractTopicsNoDuplicates() async {
        // Repeating a noun should not produce duplicate topic entries
        let topics = await analyzer.extractTopics("The garden is beautiful. I love the garden. The garden has roses.")
        let unique = Set(topics)
        XCTAssertEqual(topics.count, unique.count, "Topics should not contain duplicates")
    }

    func testExtractTopicsNouns() async {
        let topics = await analyzer.extractTopics("The restaurant served delicious pasta with fresh vegetables and herbs.")
        XCTAssertFalse(topics.isEmpty, "Text with clear nouns should produce topics")
    }
}
