import XCTest
@testable import Kinen

final class ExportServiceTests: XCTestCase {

    private func makeEntry(
        content: String = "Test journal content",
        title: String? = "Test Entry",
        mood: Mood? = .good
    ) -> JournalEntry {
        let entry = JournalEntry(content: content, title: title, mood: mood)
        entry.isPinned = false
        return entry
    }

    // MARK: - Markdown Export

    func testMarkdownExportContainsFrontmatter() {
        let entries = [makeEntry()]
        guard let url = ExportService.exportAll(entries: entries, format: .markdown) else {
            XCTFail("Export returned nil")
            return
        }
        defer { try? FileManager.default.removeItem(at: url) }

        let files = try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
        XCTAssertEqual(files?.count, 1, "Should produce one markdown file")

        if let file = files?.first, let content = try? String(contentsOf: file, encoding: .utf8) {
            XCTAssertTrue(content.contains("---"), "Should contain YAML frontmatter delimiters")
            XCTAssertTrue(content.contains("mood:"), "Should contain mood in frontmatter")
            XCTAssertTrue(content.contains("words:"), "Should contain word count")
            XCTAssertTrue(content.contains("# Test Entry"), "Should contain title as H1")
            XCTAssertTrue(content.contains("Test journal content"), "Should contain entry body")
        }
    }

    func testMarkdownPinnedEntry() {
        let entry = makeEntry()
        entry.isPinned = true
        guard let url = ExportService.exportAll(entries: [entry], format: .markdown) else {
            XCTFail("Export returned nil")
            return
        }
        defer { try? FileManager.default.removeItem(at: url) }

        if let file = try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil).first,
           let content = try? String(contentsOf: file, encoding: .utf8) {
            XCTAssertTrue(content.contains("pinned: true"), "Pinned entries should have pinned flag in frontmatter")
        }
    }

    // MARK: - JSON Export

    func testJSONExportProducesValidJSON() {
        let entries = [makeEntry(), makeEntry(content: "Second entry", title: "Entry 2")]
        guard let url = ExportService.exportAll(entries: entries, format: .json) else {
            XCTFail("Export returned nil")
            return
        }
        defer { try? FileManager.default.removeItem(at: url) }

        let jsonFile = url.appendingPathComponent("kinen-journal.json")
        guard let data = try? Data(contentsOf: jsonFile) else {
            XCTFail("Cannot read JSON file")
            return
        }

        let parsed = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
        XCTAssertNotNil(parsed, "Should be valid JSON array")
        XCTAssertEqual(parsed?.count, 2, "Should contain 2 entries")

        if let first = parsed?.first {
            XCTAssertNotNil(first["id"], "Should have id")
            XCTAssertNotNil(first["content"], "Should have content")
            XCTAssertNotNil(first["isPinned"], "Should have isPinned field")
        }
    }

    // MARK: - Plain Text Export

    func testPlainTextExport() {
        let entries = [makeEntry()]
        guard let url = ExportService.exportAll(entries: entries, format: .plainText) else {
            XCTFail("Export returned nil")
            return
        }
        defer { try? FileManager.default.removeItem(at: url) }

        let textFile = url.appendingPathComponent("kinen-journal.txt")
        guard let content = try? String(contentsOf: textFile, encoding: .utf8) else {
            XCTFail("Cannot read text file")
            return
        }

        XCTAssertTrue(content.contains("Kinen Journal Export"), "Should have header")
        XCTAssertTrue(content.contains("Test Entry"), "Should contain entry title")
        XCTAssertTrue(content.contains("Test journal content"), "Should contain entry body")
    }

    // MARK: - Empty Export

    func testEmptyExport() {
        let url = ExportService.exportAll(entries: [], format: .markdown)
        XCTAssertNotNil(url, "Should succeed even with empty array")
        if let url { try? FileManager.default.removeItem(at: url) }
    }

    // MARK: - Format Extensions

    func testFormatExtensions() {
        XCTAssertEqual(ExportService.ExportFormat.markdown.fileExtension, "md")
        XCTAssertEqual(ExportService.ExportFormat.json.fileExtension, "json")
        XCTAssertEqual(ExportService.ExportFormat.plainText.fileExtension, "txt")
    }
}
