import XCTest
@testable import Kinen

final class MarkdownRendererTests: XCTestCase {

    // MARK: - Plain text

    func testPlainText() {
        let result = MarkdownRenderer.render("Hello, world!")
        XCTAssertEqual(String(result.characters), "Hello, world!")
    }

    func testEmptyString() {
        let result = MarkdownRenderer.render("")
        XCTAssertEqual(String(result.characters), "")
    }

    func testUnicodeContent() {
        let result = MarkdownRenderer.render("日本語テスト")
        XCTAssertEqual(String(result.characters), "日本語テスト")
    }

    func testWhitespacePreserved() {
        let result = MarkdownRenderer.render("line one\nline two")
        XCTAssertEqual(String(result.characters), "line one\nline two")
    }

    // MARK: - Bold

    func testBoldTextContent() {
        let result = MarkdownRenderer.render("**bold**")
        XCTAssertEqual(String(result.characters), "bold")
    }

    func testBoldRunAttribute() {
        let result = MarkdownRenderer.render("**bold**")
        let hasBold = result.runs.contains { run in
            run.inlinePresentationIntent?.contains(.stronglyEmphasized) == true
        }
        XCTAssertTrue(hasBold, "Bold text should have .stronglyEmphasized run attribute")
    }

    // MARK: - Italic

    func testItalicTextContent() {
        let result = MarkdownRenderer.render("*italic*")
        XCTAssertEqual(String(result.characters), "italic")
    }

    func testItalicRunAttribute() {
        let result = MarkdownRenderer.render("*italic*")
        let hasItalic = result.runs.contains { run in
            run.inlinePresentationIntent?.contains(.emphasized) == true
        }
        XCTAssertTrue(hasItalic, "Italic text should have .emphasized run attribute")
    }

    // MARK: - Code

    func testCodeTextContent() {
        let result = MarkdownRenderer.render("`code`")
        XCTAssertEqual(String(result.characters), "code")
    }

    // MARK: - Mixed content

    func testMixedBoldAndPlain() {
        let result = MarkdownRenderer.render("Hello **world**!")
        XCTAssertEqual(String(result.characters), "Hello world!")
    }

    func testBoldUnicode() {
        let result = MarkdownRenderer.render("**日本語**")
        XCTAssertEqual(String(result.characters), "日本語")
    }

    func testMultipleFormatRuns() {
        let result = MarkdownRenderer.render("**a** and *b*")
        XCTAssertEqual(String(result.characters), "a and b")
    }
}
