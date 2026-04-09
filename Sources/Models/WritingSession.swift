import Foundation
import SwiftData

/// Tracks a writing session: duration, word count over time.
/// Used to show writing stats and encourage consistency.
@Model
final class WritingSession {
    var id: UUID = UUID()
    var startedAt: Date = Date()
    var endedAt: Date?
    var initialWordCount: Int = 0
    var finalWordCount: Int = 0
    var entryId: UUID?

    init(entryId: UUID? = nil, initialWordCount: Int = 0) {
        self.id = UUID()
        self.startedAt = Date()
        self.initialWordCount = initialWordCount
        self.finalWordCount = initialWordCount
        self.entryId = entryId
    }

    var duration: TimeInterval {
        (endedAt ?? Date()).timeIntervalSince(startedAt)
    }

    var wordsWritten: Int {
        max(0, finalWordCount - initialWordCount)
    }

    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        }
        return "\(seconds)s"
    }

    func finish(wordCount: Int) {
        self.endedAt = Date()
        self.finalWordCount = wordCount
    }
}
