import Foundation
import SwiftData
import OSLog
#if canImport(AppKit)
import AppKit
#endif

private let logger = Logger(subsystem: "com.kinen.app", category: "Export")

/// Export journal entries in multiple formats.
/// Supports Markdown, JSON, and plain text.
struct ExportService {

    enum ExportFormat: String, CaseIterable {
        case markdown = "Markdown"
        case json = "JSON"
        case plainText = "Plain Text"

        var fileExtension: String {
            switch self {
            case .markdown: "md"
            case .json: "json"
            case .plainText: "txt"
            }
        }
    }

    /// Export all entries to a folder.
    static func exportAll(entries: [JournalEntry], format: ExportFormat) -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("KinenExport-\(Date().timeIntervalSince1970)", isDirectory: true)

        do {
            try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

            switch format {
            case .markdown:
                for entry in entries {
                    let filename = safeFilename(entry) + ".md"
                    let content = entryToMarkdown(entry)
                    try content.write(to: tempDir.appendingPathComponent(filename), atomically: true, encoding: .utf8)
                }
            case .json:
                let data = try JSONEncoder.prettyPrinting.encode(entries.map { ExportableEntry(from: $0) })
                try data.write(to: tempDir.appendingPathComponent("kinen-journal.json"))
            case .plainText:
                var allText = "Kinen Journal Export\n" + String(repeating: "=", count: 40) + "\n\n"
                for entry in entries.sorted(by: { $0.createdAt < $1.createdAt }) {
                    allText += entryToPlainText(entry) + "\n\n" + String(repeating: "-", count: 40) + "\n\n"
                }
                try allText.write(to: tempDir.appendingPathComponent("kinen-journal.txt"), atomically: true, encoding: .utf8)
            }

            logger.info("Exported \(entries.count) entries to \(tempDir.path)")
            return tempDir
        } catch {
            logger.error("Export failed: \(error)")
            return nil
        }
    }

    /// Show save dialog and export (macOS).
    #if os(macOS)
    static func exportWithDialog(entries: [JournalEntry], format: ExportFormat) {
        guard let exportURL = exportAll(entries: entries, format: format) else { return }

        NSWorkspace.shared.open(exportURL)
    }
    #endif

    // MARK: - Formatters

    private static func entryToMarkdown(_ entry: JournalEntry) -> String {
        var md = ""

        // YAML frontmatter
        md += "---\n"
        md += "date: \(entry.createdAt.ISO8601Format())\n"
        if let mood = entry.mood {
            md += "mood: \(mood.label) \(mood.emoji)\n"
        }
        if let score = entry.sentimentScore {
            md += "sentiment: \(String(format: "%.2f", score))\n"
        }
        if !entry.safeTags.isEmpty {
            md += "tags: [\(entry.safeTags.map { $0.name }.joined(separator: ", "))]\n"
        }
        md += "words: \(entry.wordCount)\n"
        md += "---\n\n"

        // Title
        if let title = entry.title, !title.isEmpty {
            md += "# \(title)\n\n"
        }

        // Content
        md += entry.content + "\n"

        // Insights
        if !entry.safeInsights.isEmpty {
            md += "\n## AI Insights\n\n"
            for insight in entry.safeInsights {
                md += "- **[\(insight.type.rawValue)]** \(insight.content)\n"
            }
        }

        return md
    }

    private static func entryToPlainText(_ entry: JournalEntry) -> String {
        var text = ""
        text += entry.displayTitle + "\n"
        text += entry.createdAt.formatted(date: .long, time: .shortened) + "\n"
        if let mood = entry.mood {
            text += "Mood: \(mood.emoji) \(mood.label)\n"
        }
        text += "\n" + entry.content
        return text
    }

    private static func safeFilename(_ entry: JournalEntry) -> String {
        let dateStr = entry.createdAt.formatted(.dateTime.year().month().day())
        let title = entry.title ?? "entry"
        let safe = title.replacingOccurrences(of: "[^a-zA-Z0-9\\u4e00-\\u9fff-]", with: "-", options: .regularExpression)
        return "\(dateStr)-\(safe.prefix(40))"
    }
}

// MARK: - Exportable Entry (Codable)

private struct ExportableEntry: Codable {
    let id: String
    let title: String?
    let content: String
    let createdAt: Date
    let updatedAt: Date
    let mood: String?
    let moodValue: Int?
    let sentimentScore: Double?
    let wordCount: Int
    let tags: [String]
    let insights: [ExportableInsight]

    init(from entry: JournalEntry) {
        self.id = entry.id.uuidString
        self.title = entry.title
        self.content = entry.content
        self.createdAt = entry.createdAt
        self.updatedAt = entry.updatedAt
        self.mood = entry.mood?.label
        self.moodValue = entry.mood?.rawValue
        self.sentimentScore = entry.sentimentScore
        self.wordCount = entry.wordCount
        self.tags = entry.safeTags.map { $0.name }
        self.insights = entry.safeInsights.map { ExportableInsight(type: $0.type.rawValue, content: $0.content) }
    }
}

private struct ExportableInsight: Codable {
    let type: String
    let content: String
}

private extension JSONEncoder {
    static var prettyPrinting: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}
