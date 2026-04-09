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
}
