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

    // MARK: - Edge Cases (extended)

    func testParseEmptyPromptsReturnsEmpty() {
        let result = EntryEditorSheet.parseTemplateContent("<!-- daily-0 -->\nSome content", prompts: [])
        XCTAssertTrue(result.isEmpty, "Empty prompts array should yield empty result")
    }

    func testParseUnicodeContentPreserved() {
        let content = """
        <!-- daily-0 -->
        今日は最高だった 🎉

        <!-- daily-1 -->
        感謝の気持ち 😊
        """
        let prompts = [
            TemplatePrompt(id: "daily-0", title: nil, placeholder: ""),
            TemplatePrompt(id: "daily-1", title: nil, placeholder: ""),
        ]
        let result = EntryEditorSheet.parseTemplateContent(content, prompts: prompts)
        XCTAssertEqual(result["daily-0"], "今日は最高だった 🎉")
        XCTAssertEqual(result["daily-1"], "感謝の気持ち 😊")
    }

    func testParseDuplicateMarkerLastValueWins() {
        let content = """
        <!-- daily-0 -->
        First value

        <!-- daily-0 -->
        Second value
        """
        let prompts = [TemplatePrompt(id: "daily-0", title: nil, placeholder: "")]
        let result = EntryEditorSheet.parseTemplateContent(content, prompts: prompts)
        XCTAssertEqual(result["daily-0"], "Second value", "Duplicate marker: last occurrence should win")
    }

    func testParseAdjacentMarkersGiveEmptyStrings() {
        let content = """
        <!-- daily-0 -->
        <!-- daily-1 -->
        """
        let prompts = [
            TemplatePrompt(id: "daily-0", title: nil, placeholder: ""),
            TemplatePrompt(id: "daily-1", title: nil, placeholder: ""),
        ]
        let result = EntryEditorSheet.parseTemplateContent(content, prompts: prompts)
        XCTAssertEqual(result["daily-0"] ?? "", "", "Adjacent markers should give empty string for first prompt")
    }

    func testParsePartialMarkersOnlyMatchedPromptInResult() {
        let content = """
        <!-- daily-0 -->
        Only first section present
        """
        let prompts = [
            TemplatePrompt(id: "daily-0", title: nil, placeholder: ""),
            TemplatePrompt(id: "daily-1", title: nil, placeholder: ""),
        ]
        let result = EntryEditorSheet.parseTemplateContent(content, prompts: prompts)
        XCTAssertEqual(result["daily-0"], "Only first section present")
        XCTAssertNil(result["daily-1"], "Prompt without marker should be absent from result")
    }

    func testParseLegacyNilTitlePromptsFirstGetsAll() {
        // Multiple nil-title prompts + no markers → first prompt gets entire content
        let content = "Just some freeform text without markers or titles"
        let prompts = [
            TemplatePrompt(id: "q-0", title: nil, placeholder: ""),
            TemplatePrompt(id: "q-1", title: nil, placeholder: ""),
        ]
        let result = EntryEditorSheet.parseTemplateContent(content, prompts: prompts)
        XCTAssertEqual(result["q-0"], content, "First prompt should receive full content as fallback")
        XCTAssertNil(result["q-1"], "Non-first nil-title prompt should not appear in result")
    }

    func testParseStableMarkerTakesPrecedenceOverLegacyTitle() {
        // When stable markers are present, legacy title matching should NOT run
        let prompts = [
            TemplatePrompt(id: "daily-0", title: "Best moment", placeholder: ""),
        ]
        let content = """
        <!-- daily-0 -->
        Marker-based response (no bold title)
        """
        let result = EntryEditorSheet.parseTemplateContent(content, prompts: prompts)
        XCTAssertEqual(result["daily-0"], "Marker-based response (no bold title)",
                       "Stable marker path should take precedence over legacy title matching")
    }
}
