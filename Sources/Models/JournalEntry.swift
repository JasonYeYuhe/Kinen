import Foundation
import SwiftData

@Model
final class JournalEntry {
    // CloudKit requires all properties to have default values
    var id: UUID = UUID()
    var content: String = ""
    var title: String?
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var mood: Mood?
    var sentimentScore: Double?
    var wordCount: Int = 0
    var isBookmarked: Bool = false
    var weather: String?
    var location: String?
    var template: JournalTemplate?
    var writingDuration: TimeInterval = 0
    var isHidden: Bool = false

    @Attribute(.externalStorage)
    var photoData: Data?

    var audioFilename: String?

    // Journal notebook (optional — nil means "All Entries" / default)
    var journal: Journal?

    // CloudKit requires relationships to be optional
    @Relationship(deleteRule: .nullify, inverse: \Tag.entries)
    var tags: [Tag]?

    @Relationship(deleteRule: .cascade)
    var insights: [EntryInsight]?

    /// Safe accessor — always returns non-nil array (Gemini recommendation)
    var safeTags: [Tag] { tags ?? [] }
    var safeInsights: [EntryInsight] { insights ?? [] }

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
        self.tags = tags  // Always [] not nil (Gemini safety rule)
        self.insights = []
    }

    /// Safe append to optional tags array
    func addTag(_ tag: Tag) {
        if tags != nil { tags!.append(tag) } else { tags = [tag] }
    }

    /// Safe append to optional insights array
    func addInsight(_ insight: EntryInsight) {
        if insights != nil { insights!.append(insight) } else { insights = [insight] }
    }

    var preview: String {
        let firstLine = content.components(separatedBy: "\n").first ?? content
        if firstLine.count > 100 {
            return String(firstLine.prefix(100)) + "..."
        }
        return firstLine
    }

    var displayTitle: String {
        if let title, !title.isEmpty { return title }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }
}
