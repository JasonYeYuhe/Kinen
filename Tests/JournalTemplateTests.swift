import XCTest
@testable import Kinen

final class JournalTemplateTests: XCTestCase {

    // MARK: - allCases

    func testAllCasesCount() {
        XCTAssertEqual(JournalTemplate.allCases.count, 8)
    }

    // MARK: - id

    func testIdMatchesRawValue() {
        for template in JournalTemplate.allCases {
            XCTAssertEqual(template.id, template.rawValue)
        }
    }

    // MARK: - Rawvalue Roundtrip

    func testRawValueRoundtrip() {
        for template in JournalTemplate.allCases {
            XCTAssertEqual(JournalTemplate(rawValue: template.rawValue), template)
        }
    }

    // MARK: - icon (SF Symbol names, non-empty)

    func testAllIconsNonEmpty() {
        for template in JournalTemplate.allCases {
            XCTAssertFalse(template.icon.isEmpty, "\(template.rawValue) icon should not be empty")
        }
    }

    func testIconsAreUnique() {
        let icons = JournalTemplate.allCases.map(\.icon)
        XCTAssertEqual(Set(icons).count, icons.count, "Each template should have a unique icon")
    }

    // MARK: - prompts count

    func testFreeWriteHasOnePrompt() {
        XCTAssertEqual(JournalTemplate.freeWrite.prompts.count, 1)
    }

    func testDailyReviewHasFourPrompts() {
        XCTAssertEqual(JournalTemplate.dailyReview.prompts.count, 4)
    }

    func testGratitudeHasFourPrompts() {
        XCTAssertEqual(JournalTemplate.gratitude.prompts.count, 4)
    }

    func testMorningPagesHasOnePrompt() {
        XCTAssertEqual(JournalTemplate.morningPages.prompts.count, 1)
    }

    func testCbtThreeColumnHasFourPrompts() {
        XCTAssertEqual(JournalTemplate.cbtThreeColumn.prompts.count, 4)
    }

    func testDreamJournalHasFourPrompts() {
        XCTAssertEqual(JournalTemplate.dreamJournal.prompts.count, 4)
    }

    func testGoalReflectionHasFourPrompts() {
        XCTAssertEqual(JournalTemplate.goalReflection.prompts.count, 4)
    }

    func testWeeklyReviewHasFourPrompts() {
        XCTAssertEqual(JournalTemplate.weeklyReview.prompts.count, 4)
    }

    // MARK: - prompts ids are unique within each template

    func testPromptIdsAreUniquePerTemplate() {
        for template in JournalTemplate.allCases {
            let ids = template.prompts.map(\.id)
            XCTAssertEqual(Set(ids).count, ids.count,
                           "\(template.rawValue) has duplicate prompt ids")
        }
    }

    // MARK: - prompts placeholders are non-empty

    func testAllPromptPlaceholdersNonEmpty() {
        for template in JournalTemplate.allCases {
            for prompt in template.prompts {
                XCTAssertFalse(prompt.placeholder.isEmpty,
                               "\(template.rawValue) prompt '\(prompt.id)' has empty placeholder")
            }
        }
    }

    // MARK: - name

    func testAllNamesNonEmpty() {
        for template in JournalTemplate.allCases {
            XCTAssertFalse(template.name.isEmpty, "\(template.rawValue) name should not be empty")
        }
    }

    func testNamesAreDistinct() {
        let names = JournalTemplate.allCases.map(\.name)
        XCTAssertEqual(Set(names).count, names.count, "Each template should have a unique name")
    }

    // MARK: - description

    func testAllDescriptionsNonEmpty() {
        for template in JournalTemplate.allCases {
            XCTAssertFalse(template.description.isEmpty,
                           "\(template.rawValue) description should not be empty")
        }
    }

    // MARK: - prompt title optionality

    func testFreeWriteAndMorningPagesHaveNilTitlePrompt() {
        XCTAssertNil(JournalTemplate.freeWrite.prompts[0].title,
                     "freeWrite single prompt should have nil title (unstructured writing)")
        XCTAssertNil(JournalTemplate.morningPages.prompts[0].title,
                     "morningPages single prompt should have nil title (stream-of-consciousness)")
    }

    func testStructuredTemplatesPromptsHaveNonNilTitles() {
        let structured: [JournalTemplate] = [
            .dailyReview, .gratitude, .cbtThreeColumn,
            .dreamJournal, .goalReflection, .weeklyReview
        ]
        for template in structured {
            for prompt in template.prompts {
                XCTAssertNotNil(prompt.title,
                                "\(template.rawValue) prompt '\(prompt.id)' should have a non-nil title")
            }
        }
    }
}
