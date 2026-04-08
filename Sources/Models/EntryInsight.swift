import Foundation
import SwiftData

/// An AI-generated insight attached to a journal entry.
@Model
final class EntryInsight {
    var id: UUID
    var type: InsightType
    var content: String
    var createdAt: Date

    var entry: JournalEntry?

    init(type: InsightType, content: String) {
        self.id = UUID()
        self.type = type
        self.content = content
        self.createdAt = Date()
    }
}

enum InsightType: String, Codable {
    case sentiment       // "Your mood seems more positive today"
    case pattern         // "You tend to feel better on days you exercise"
    case suggestion      // "Consider journaling about what made today good"
    case topicExtraction // "Main topics: work, family, health"
    case streak          // "7-day journaling streak!"
}
