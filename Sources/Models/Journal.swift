import Foundation
import SwiftData
import SwiftUI

/// A journal notebook. Users can create multiple journals to organize
/// entries by category (Personal, Work, Travel, etc.).
@Model
final class Journal {
    var id: UUID = UUID()
    var name: String = ""
    var icon: String = "book.closed"
    var colorHex: String = "8B5CF6" // purple
    var createdAt: Date = Date()
    var isDefault: Bool = false

    @Relationship(deleteRule: .nullify, inverse: \JournalEntry.journal)
    var entries: [JournalEntry]?

    var safeEntries: [JournalEntry] { entries ?? [] }

    var entryCount: Int { safeEntries.count }

    var color: Color {
        Color(hex: colorHex) ?? .purple
    }

    init(name: String, icon: String = "book.closed", colorHex: String = "8B5CF6", isDefault: Bool = false) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.createdAt = Date()
        self.isDefault = isDefault
        self.entries = []
    }

    /// Predefined journal presets
    static let presets: [(name: String, icon: String, color: String)] = [
        ("Personal", "person.fill", "8B5CF6"),     // purple
        ("Work", "briefcase.fill", "3B82F6"),       // blue
        ("Travel", "airplane", "06B6D4"),           // cyan
        ("Health", "heart.fill", "10B981"),          // green
        ("Creative", "paintbrush.fill", "F97316"),  // orange
        ("Dreams", "moon.stars.fill", "6366F1"),    // indigo
    ]
}
