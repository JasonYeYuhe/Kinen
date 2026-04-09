import Foundation
import SwiftData

@Model
final class EntryInsight {
    var id: UUID = UUID()
    var type: InsightType = InsightType.sentiment
    var content: String = ""
    var createdAt: Date = Date()

    var entry: JournalEntry?

    init(type: InsightType, content: String) {
        self.id = UUID()
        self.type = type
        self.content = content
        self.createdAt = Date()
    }
}

enum InsightType: String, Codable {
    case sentiment
    case pattern
    case suggestion
    case topicExtraction
    case streak
}
