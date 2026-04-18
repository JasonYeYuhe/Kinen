import XCTest
@testable import Kinen

final class PromptGeneratorTests: XCTestCase {
    func testGenerateWithMood() {
        let prompt = PromptGenerator.generatePrompt(currentMood: .great, recentEntries: [])
        XCTAssertFalse(prompt.isEmpty)
    }

    func testGenerateWithoutMood() {
        let prompt = PromptGenerator.generatePrompt(currentMood: nil, recentEntries: [])
        XCTAssertFalse(prompt.isEmpty)
    }

    func testMultiplePrompts() {
        let prompts = PromptGenerator.generatePrompts(currentMood: .bad, recentEntries: [], count: 3)
        XCTAssertEqual(prompts.count, 3)
        // All prompts should be unique
        XCTAssertEqual(Set(prompts).count, prompts.count)
    }

    func testMoodBasedPromptsVary() {
        let great = PromptGenerator.generatePrompt(currentMood: .great, recentEntries: [])
        let terrible = PromptGenerator.generatePrompt(currentMood: .terrible, recentEntries: [])
        // Different moods should generally produce different prompts
        // (not guaranteed due to randomness, but highly likely)
        XCTAssertFalse(great.isEmpty)
        XCTAssertFalse(terrible.isEmpty)
    }

    func testTemplatePrompts() {
        for template in JournalTemplate.allCases {
            XCTAssertFalse(template.prompts.isEmpty, "\(template.name) should have prompts")
            XCTAssertFalse(template.name.isEmpty)
            XCTAssertFalse(template.icon.isEmpty)
        }
    }

    func testMoodEnum() {
        XCTAssertEqual(Mood.allCases.count, 5)
        for mood in Mood.allCases {
            XCTAssertFalse(mood.emoji.isEmpty)
            XCTAssertFalse(mood.label.isEmpty)
            XCTAssertGreaterThanOrEqual(mood.normalizedValue, 0)
            XCTAssertLessThanOrEqual(mood.normalizedValue, 1)
        }
    }

    // MARK: - Historical Prompt Paths

    func testHistoricalPromptYearAgo() {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let oneYearAgo = cal.date(byAdding: .year, value: -1, to: today)!
        let entry = JournalEntry(content: "Hiking trip was amazing", createdAt: oneYearAgo)
        let prompt = PromptGenerator.generatePrompt(currentMood: nil, recentEntries: [entry], today: today)
        XCTAssertTrue(prompt.contains(entry.preview),
                      "Year-ago entry preview should appear in the historical prompt")
    }

    func testHistoricalPromptMonthAgo() {
        // oneMonthAgo is ~1 year different from oneYearAgo, so the year-ago guard won't fire
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let oneMonthAgo = cal.date(byAdding: .month, value: -1, to: today)!
        let entry = JournalEntry(content: "Started a new project", createdAt: oneMonthAgo)
        let prompt = PromptGenerator.generatePrompt(currentMood: nil, recentEntries: [entry], today: today)
        XCTAssertTrue(prompt.contains(entry.preview),
                      "Month-ago entry preview should appear in the historical prompt when no year-ago entry exists")
    }

    func testYearAgoPrecedenceOverMonthAgo() {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let oneYearAgo = cal.date(byAdding: .year, value: -1, to: today)!
        let oneMonthAgo = cal.date(byAdding: .month, value: -1, to: today)!
        let yearEntry = JournalEntry(content: "Year-ago memory", createdAt: oneYearAgo)
        let monthEntry = JournalEntry(content: "Month-ago memory", createdAt: oneMonthAgo)
        let prompt = PromptGenerator.generatePrompt(
            currentMood: nil,
            recentEntries: [yearEntry, monthEntry],
            today: today
        )
        XCTAssertTrue(prompt.contains(yearEntry.preview),
                      "Year-ago entry should take precedence over month-ago entry")
        XCTAssertFalse(prompt.contains(monthEntry.preview),
                       "Month-ago preview should not appear when year-ago entry is present")
    }

    // MARK: - generatePrompts Paths

    func testGeneratePromptsNegativeSentimentAddsCBTPrompt() {
        // avgSentiment = -0.5 < -0.2 → CBT prompt appended
        // With no mood: gratitude + reflection + cbt = 3 prompts for count=3
        let entries = (0..<3).map { _ -> JournalEntry in
            let e = JournalEntry(content: "hard day")
            e.sentimentScore = -0.5
            return e
        }
        let prompts = PromptGenerator.generatePrompts(currentMood: nil, recentEntries: entries, count: 3)
        XCTAssertEqual(prompts.count, 3,
                       "Negative-sentiment entries should trigger CBT prompt, filling all 3 slots")
    }

    func testGeneratePromptsPositiveSentimentNoCBT() {
        // avgSentiment = 0.5 >= -0.2 → no CBT → only gratitude + reflection = 2 prompts
        let entries = (0..<3).map { _ -> JournalEntry in
            let e = JournalEntry(content: "great day")
            e.sentimentScore = 0.5
            return e
        }
        let prompts = PromptGenerator.generatePrompts(currentMood: nil, recentEntries: entries, count: 3)
        XCTAssertEqual(prompts.count, 2,
                       "Positive-sentiment entries should not trigger CBT; only 2 prompts returned")
    }

    func testGeneratePromptsCountCap() {
        // count=1 should cap output even when more prompts are available
        let prompts = PromptGenerator.generatePrompts(currentMood: .great, recentEntries: [], count: 1)
        XCTAssertEqual(prompts.count, 1, "count parameter should cap number of returned prompts")
    }

    func testGeneratePromptsWithMoodAndNegativeSentimentReturnsFour() {
        // mood + gratitude + reflection + cbt = 4 → all fit in count=4
        let entries = (0..<3).map { _ -> JournalEntry in
            let e = JournalEntry(content: "rough week")
            e.sentimentScore = -0.6
            return e
        }
        let prompts = PromptGenerator.generatePrompts(currentMood: .terrible, recentEntries: entries, count: 4)
        XCTAssertEqual(prompts.count, 4,
                       "With mood + negative sentiment, all 4 prompt slots should be filled")
    }

    func testGeneratePromptsNoMoodNoEntriesReturnsTwoPrompts() {
        // No mood, no entries → gratitude + reflection only (avgSentiment=0 → no CBT)
        let prompts = PromptGenerator.generatePrompts(currentMood: nil, recentEntries: [], count: 3)
        XCTAssertEqual(prompts.count, 2,
                       "Without mood or negative sentiment, only gratitude + reflection prompts are added")
    }
}
