import Foundation

/// Plain-data aggregation of journal data for a clinician handoff.
/// Built by TherapistHandoffService from JournalEntry data; consumed by
/// TherapistHandoffSheet for preview and PDFRenderer / Markdown export.
///
/// Designed to be deterministic and Codable for testing and JSON export.
struct HandoffReport: Codable, Equatable {

    let generatedAt: Date
    let dateRange: DateRange
    let overview: Overview
    let moodTrend: [MoodPoint]
    let topThemes: [Theme]
    let cognitiveDistortions: [DistortionStat]
    let highlightedEntries: [HighlightedEntry]
    let crisisFlags: [CrisisFlag]
    let userTopics: String

    struct DateRange: Codable, Equatable {
        let start: Date
        let end: Date

        var dayCount: Int {
            max(1, Calendar.current.dateComponents([.day], from: start, to: end).day ?? 1)
        }
    }

    struct Overview: Codable, Equatable {
        let totalEntries: Int
        let totalWords: Int
        let averageMood: Double?      // 1.0 — 5.0, nil if no mood entries
        let averageSentiment: Double? // -1.0 — 1.0, nil if no scored entries
        let highestMoodDay: Date?
        let lowestMoodDay: Date?
        let writingDays: Int
        let longestSilence: Int       // longest gap (days) between entries in range
    }

    struct MoodPoint: Codable, Equatable {
        let date: Date
        let mood: Int  // 1—5
    }

    struct Theme: Codable, Equatable {
        let name: String
        let count: Int
    }

    struct DistortionStat: Codable, Equatable {
        let name: String         // localized CBT distortion name
        let count: Int           // entries where this distortion was detected
        let exampleSentence: String?
    }

    struct HighlightedEntry: Codable, Equatable {
        let date: Date
        let title: String?
        let mood: Int?
        let sentiment: Double?
        let snippet: String      // first ~280 chars, sanitized
        let reason: HighlightReason

        enum HighlightReason: String, Codable {
            case lowestMood
            case highestMood
            case largestDeviation
            case crisis
            case userPinned
        }
    }

    struct CrisisFlag: Codable, Equatable {
        let date: Date
        let severity: String  // "high" | "moderate"
        let snippet: String
    }

    /// Selectable report sections — user can opt in/out per section.
    struct Sections: Codable, Equatable {
        var overview: Bool = true
        var moodTrend: Bool = true
        var topThemes: Bool = true
        var cognitiveDistortions: Bool = true
        var highlightedEntries: Bool = true
        var crisisFlags: Bool = true
        var userTopics: Bool = true

        static let all = Sections()
    }
}
