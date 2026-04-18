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

    // MARK: - Markdown: no title

    func testMarkdownNoTitleOmitsH1() {
        let entry = makeEntry(title: nil)
        guard let url = ExportService.exportAll(entries: [entry], format: .markdown) else {
            XCTFail("Export returned nil"); return
        }
        defer { try? FileManager.default.removeItem(at: url) }

        if let file = try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil).first,
           let content = try? String(contentsOf: file, encoding: .utf8) {
            XCTAssertFalse(content.contains("# "), "Entry without title should not have H1 heading")
            XCTAssertTrue(content.contains("Test journal content"), "Should still contain body")
        }
    }

    // MARK: - Markdown: tags in frontmatter

    func testMarkdownTagsInFrontmatter() {
        let entry = makeEntry()
        let tag = Tag(name: "work", colorHex: "#0000FF", isAutoGenerated: false)
        entry.addTag(tag)
        guard let url = ExportService.exportAll(entries: [entry], format: .markdown) else {
            XCTFail("Export returned nil"); return
        }
        defer { try? FileManager.default.removeItem(at: url) }

        if let file = try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil).first,
           let content = try? String(contentsOf: file, encoding: .utf8) {
            XCTAssertTrue(content.contains("tags:"), "Should include tags line in frontmatter")
            XCTAssertTrue(content.contains("work"), "Should include tag name")
        }
    }

    // MARK: - Markdown: sentiment score

    func testMarkdownSentimentScoreInFrontmatter() {
        let entry = makeEntry()
        entry.sentimentScore = 0.75
        guard let url = ExportService.exportAll(entries: [entry], format: .markdown) else {
            XCTFail("Export returned nil"); return
        }
        defer { try? FileManager.default.removeItem(at: url) }

        if let file = try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil).first,
           let content = try? String(contentsOf: file, encoding: .utf8) {
            XCTAssertTrue(content.contains("sentiment:"), "Should include sentiment score in frontmatter")
            XCTAssertTrue(content.contains("0.75"), "Should include formatted score value")
        }
    }

    // MARK: - Markdown: AI insights section

    func testMarkdownAIInsightsSection() {
        let entry = makeEntry()
        entry.addInsight(EntryInsight(type: .suggestion, content: "Try meditation"))
        guard let url = ExportService.exportAll(entries: [entry], format: .markdown) else {
            XCTFail("Export returned nil"); return
        }
        defer { try? FileManager.default.removeItem(at: url) }

        if let file = try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil).first,
           let content = try? String(contentsOf: file, encoding: .utf8) {
            XCTAssertTrue(content.contains("## AI Insights"), "Should include AI Insights section")
            XCTAssertTrue(content.contains("Try meditation"), "Should include insight content")
        }
    }

    // MARK: - Markdown: multiple entries → multiple files

    func testMarkdownMultipleEntriesCreatesMultipleFiles() {
        let entries = [
            makeEntry(content: "Entry one", title: "First"),
            makeEntry(content: "Entry two", title: "Second"),
            makeEntry(content: "Entry three", title: "Third"),
        ]
        guard let url = ExportService.exportAll(entries: entries, format: .markdown) else {
            XCTFail("Export returned nil"); return
        }
        defer { try? FileManager.default.removeItem(at: url) }

        let files = (try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)) ?? []
        XCTAssertEqual(files.count, 3, "Three entries should create three markdown files")
    }

    // MARK: - Markdown: special chars in title → safe filename

    func testMarkdownSpecialCharsTitleSafeFilename() {
        let entry = makeEntry(title: "Hello / World: Test?")
        guard let url = ExportService.exportAll(entries: [entry], format: .markdown) else {
            XCTFail("Export returned nil"); return
        }
        defer { try? FileManager.default.removeItem(at: url) }

        let files = (try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)) ?? []
        XCTAssertEqual(files.count, 1, "Should produce exactly one file")
        if let filename = files.first?.lastPathComponent {
            XCTAssertFalse(filename.contains("/"), "Filename must not contain forward slash")
            XCTAssertFalse(filename.contains(":"), "Filename must not contain colon")
            XCTAssertFalse(filename.contains("?"), "Filename must not contain question mark")
        }
    }

    // MARK: - JSON: mood fields present

    func testJSONExportContainsMoodFields() {
        let entry = makeEntry(mood: .great)
        guard let url = ExportService.exportAll(entries: [entry], format: .json) else {
            XCTFail("Export returned nil"); return
        }
        defer { try? FileManager.default.removeItem(at: url) }

        let jsonFile = url.appendingPathComponent("kinen-journal.json")
        guard let data = try? Data(contentsOf: jsonFile),
              let parsed = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
              let first = parsed.first else {
            XCTFail("Cannot parse JSON"); return
        }
        XCTAssertNotNil(first["mood"], "Should include mood label string")
        XCTAssertNotNil(first["moodValue"], "Should include raw mood integer value")
    }

    // MARK: - Plain text: entry without mood

    func testPlainTextNoMoodLine() {
        let entry = makeEntry(mood: nil)
        guard let url = ExportService.exportAll(entries: [entry], format: .plainText) else {
            XCTFail("Export returned nil"); return
        }
        defer { try? FileManager.default.removeItem(at: url) }

        let textFile = url.appendingPathComponent("kinen-journal.txt")
        guard let content = try? String(contentsOf: textFile, encoding: .utf8) else {
            XCTFail("Cannot read text file"); return
        }
        XCTAssertFalse(content.contains("Mood:"), "Entry without mood should omit mood line")
        XCTAssertTrue(content.contains("Test journal content"), "Should still contain entry body")
    }
}
