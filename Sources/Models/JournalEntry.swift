import Foundation
import SwiftData

@Model
final class JournalEntry {
    var id: UUID
    var content: String
    var title: String?
    var createdAt: Date
    var updatedAt: Date
    var mood: Mood?
    var sentimentScore: Double? // -1.0 (negative) to 1.0 (positive), from NL framework
    var wordCount: Int
    var isBookmarked: Bool
    var weather: String?
    var location: String?
    var template: JournalTemplate?
    var writingDuration: TimeInterval
    var isHidden: Bool

    @Attribute(.externalStorage)
    var photoData: Data?

    var audioFilename: String? // relative path in app's documents

    @Relationship(deleteRule: .nullify, inverse: \Tag.entries)
    var tags: [Tag]

    @Relationship(deleteRule: .cascade)
    var insights: [EntryInsight]

    init(
        content: String,
        title: String? = nil,
        mood: Mood? = nil,
        template: JournalTemplate? = nil,
        tags: [Tag] = [],
        createdAt: Date = Date()
    ) {
        self.id = UUID()
        self.content = content
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = createdAt
        self.mood = mood
        self.template = template
        self.sentimentScore = nil
        self.wordCount = content.split(separator: " ").count
        self.isBookmarked = false
        self.isHidden = false
        self.writingDuration = 0
        self.tags = tags
        self.insights = []
    }

    /// Preview/summary: first line or first 100 chars
    var preview: String {
        let firstLine = content.components(separatedBy: "\n").first ?? content
        if firstLine.count > 100 {
            return String(firstLine.prefix(100)) + "..."
        }
        return firstLine
    }

    /// Display title: explicit title or date-based
    var displayTitle: String {
        if let title, !title.isEmpty { return title }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }
}
