import XCTest
@testable import Kinen

final class TemplateParsingTests: XCTestCase {

    private let testPrompts = [
        TemplatePrompt(id: "daily-0", title: "Best moment", placeholder: ""),
        TemplatePrompt(id: "daily-1", title: "Challenge", placeholder: ""),
        TemplatePrompt(id: "daily-2", title: "Lesson", placeholder: ""),
    ]

    // MARK: - Stable Marker Format

    func testParseStableMarkers() {
        let content = """
        <!-- daily-0 -->
        **Best moment**
        Had a great lunch with friends

        <!-- daily-1 -->
        **Challenge**
        Deadline pressure at work

        <!-- daily-2 -->
        **Lesson**
        Take breaks more often
        """

        let result = EntryEditorSheet.parseTemplateContent(content, prompts: testPrompts)

        XCTAssertEqual(result["daily-0"], "Had a great lunch with friends")
        XCTAssertEqual(result["daily-1"], "Deadline pressure at work")
        XCTAssertEqual(result["daily-2"], "Take breaks more often")
    }

    func testParseStableMarkersWithoutTitles() {
        let content = """
        <!-- daily-0 -->
        Just a plain response

        <!-- daily-1 -->
        Another response
        """

        let prompts = [
            TemplatePrompt(id: "daily-0", title: nil, placeholder: ""),
            TemplatePrompt(id: "daily-1", title: nil, placeholder: ""),
        ]

        let result = EntryEditorSheet.parseTemplateContent(content, prompts: prompts)

        XCTAssertEqual(result["daily-0"], "Just a plain response")
        XCTAssertEqual(result["daily-1"], "Another response")
    }

    // MARK: - Legacy Format (title-based)

    func testParseLegacyTitleFormat() {
        let content = """
        **Best moment**
        A wonderful day at the park

        **Challenge**
        Traffic was terrible

        **Lesson**
        Leave earlier next time
        """

        let result = EntryEditorSheet.parseTemplateContent(content, prompts: testPrompts)

        XCTAssertEqual(result["daily-0"], "A wonderful day at the park")
        XCTAssertEqual(result["daily-1"], "Traffic was terrible")
        XCTAssertEqual(result["daily-2"], "Leave earlier next time")
    }

    // MARK: - Edge Cases

    func testParseEmptyContent() {
        let result = EntryEditorSheet.parseTemplateContent("", prompts: testPrompts)
        XCTAssertTrue(result.isEmpty || result.values.allSatisfy { $0.isEmpty })
    }

    func testParseSinglePromptFallback() {
        // When no markers or titles found, entire content goes to first prompt
        let content = "Just some plain text without any markers"
        let prompts = [TemplatePrompt(id: "free-0", title: nil, placeholder: "")]

        let result = EntryEditorSheet.parseTemplateContent(content, prompts: prompts)
        XCTAssertEqual(result["free-0"], "Just some plain text without any markers")
    }

    func testParseIgnoresUnknownMarkers() {
        let content = """
        <!-- unknown-id -->
        This should be ignored

        <!-- daily-0 -->
        **Best moment**
        Real content here
        """

        let result = EntryEditorSheet.parseTemplateContent(content, prompts: testPrompts)
        XCTAssertEqual(result["daily-0"], "Real content here")
        XCTAssertNil(result["unknown-id"])
    }

    func testParseMultilineResponse() {
        let content = """
        <!-- daily-0 -->
        **Best moment**
        Line one of my response.
        Line two continues here.
        And a third line too.

        <!-- daily-1 -->
        **Challenge**
        Short response
        """

        let result = EntryEditorSheet.parseTemplateContent(content, prompts: testPrompts)
        XCTAssertTrue(result["daily-0"]!.contains("Line one"))
        XCTAssertTrue(result["daily-0"]!.contains("third line"))
        XCTAssertEqual(result["daily-1"], "Short response")
    }
}
