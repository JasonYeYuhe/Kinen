import Foundation
import SwiftData
import OSLog

private let logger = Logger(subsystem: "com.jasonye.kinen", category: "RecapGenerator")

/// Generates weekly and monthly recap summaries from journal entries.
/// All analysis is local using NaturalLanguage framework data.
struct RecapGenerator {

    struct Recap {
        let period: String // "Week of Apr 7" or "March 2026"
        let entryCount: Int
        let totalWords: Int
        let averageMood: Double? // 1-5
        let moodTrend: MoodTrend
        let topThemes: [String]
        let topEmotions: [String]
        let streakDays: Int
        let highlights: [String] // key sentences from positive entries
        let challenges: [String] // key sentences from negative entries
        let growthNote: String
        let actionItem: String
    }

    enum MoodTrend: String {
        case improving = "Improving"
        case declining = "Declining"
        case stable = "Stable"
        case insufficient = "Not enough data"

        var emoji: String {
            switch self {
            case .improving: "📈"
            case .declining: "📉"
            case .stable: "➡️"
            case .insufficient: "❓"
            }
        }

        var displayName: String {
            switch self {
            case .improving: String(localized: "recap.trend.improving")
            case .declining: String(localized: "recap.trend.declining")
            case .stable: String(localized: "recap.trend.stable")
            case .insufficient: String(localized: "recap.trend.insufficient")
            }
        }
    }

    /// Generate a weekly recap for the given week.
    static func weeklyRecap(entries: [JournalEntry], weekOf: Date) -> Recap {
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: weekOf)?.start ?? weekOf
        let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek) ?? startOfWeek

        let weekEntries = entries.filter { $0.createdAt >= startOfWeek && $0.createdAt < endOfWeek }
            .sorted { $0.createdAt < $1.createdAt }

        return generateRecap(
            entries: weekEntries,
            period: String(format: String(localized: "recap.period.week"), startOfWeek.formatted(.dateTime.month().day())),
            allEntries: entries
        )
    }

    /// Generate a monthly recap.
    static func monthlyRecap(entries: [JournalEntry], monthOf: Date) -> Recap {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: monthOf)
        let startOfMonth = calendar.date(from: components) ?? monthOf
        let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth) ?? startOfMonth

        let monthEntries = entries.filter { $0.createdAt >= startOfMonth && $0.createdAt < endOfMonth }
            .sorted { $0.createdAt < $1.createdAt }

        return generateRecap(
            entries: monthEntries,
            period: startOfMonth.formatted(.dateTime.year().month(.wide)),
            allEntries: entries
        )
    }

    // MARK: - Core Generation

    private static func generateRecap(entries: [JournalEntry], period: String, allEntries: [JournalEntry]) -> Recap {
        let moods = entries.compactMap { $0.mood }
        let sentiments = entries.compactMap { $0.sentimentScore }
        let totalWords = entries.reduce(0) { $0 + $1.wordCount }

        // Average mood
        let avgMood: Double? = moods.isEmpty ? nil : Double(moods.map { $0.rawValue }.reduce(0, +)) / Double(moods.count)

        // Mood trend (first half vs second half)
        let moodTrend = calculateMoodTrend(sentiments: sentiments)

        // Top themes from tags
        let tagCounts = Dictionary(grouping: entries.flatMap { $0.safeTags }) { $0.name }
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }
        let topThemes = Array(tagCounts.prefix(5).map { $0.key })

        // Emotion analysis
        let topEmotions = analyzeEmotions(entries: entries)

        // Streak
        let streakDays = calculateStreak(entries: entries)

        // Highlights (positive entries)
        let highlights = entries
            .filter { ($0.sentimentScore ?? 0) > 0.3 }
            .prefix(3)
            .map { $0.preview }

        // Challenges (negative entries)
        let challenges = entries
            .filter { ($0.sentimentScore ?? 0) < -0.3 }
            .prefix(3)
            .map { $0.preview }

        // Growth note
        let growthNote = generateGrowthNote(avgMood: avgMood, trend: moodTrend, entryCount: entries.count)

        // Action item
        let actionItem = generateActionItem(topThemes: topThemes, trend: moodTrend, challenges: challenges)

        return Recap(
            period: period,
            entryCount: entries.count,
            totalWords: totalWords,
            averageMood: avgMood,
            moodTrend: moodTrend,
            topThemes: topThemes,
            topEmotions: topEmotions,
            streakDays: streakDays,
            highlights: highlights,
            challenges: challenges,
            growthNote: growthNote,
            actionItem: actionItem
        )
    }

    private static func calculateMoodTrend(sentiments: [Double]) -> MoodTrend {
        guard sentiments.count >= 3 else { return .insufficient }
        let mid = sentiments.count / 2
        let firstHalf = sentiments.prefix(mid).reduce(0, +) / Double(mid)
        let secondHalf = sentiments.suffix(sentiments.count - mid).reduce(0, +) / Double(sentiments.count - mid)
        let diff = secondHalf - firstHalf
        if diff > 0.15 { return .improving }
        if diff < -0.15 { return .declining }
        return .stable
    }

    private static func analyzeEmotions(entries: [JournalEntry]) -> [String] {
        var emotions: [String: Int] = [:]
        for entry in entries {
            if let mood = entry.mood {
                emotions[mood.label, default: 0] += 1
            }
        }
        return emotions.sorted { $0.value > $1.value }.prefix(3).map { $0.key }
    }

    private static func calculateStreak(entries: [JournalEntry]) -> Int {
        let calendar = Calendar.current
        let dates = Set(entries.map { calendar.startOfDay(for: $0.createdAt) })
        var streak = 0
        var checkDate = dates.max() ?? Date()
        while dates.contains(calendar.startOfDay(for: checkDate)) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = prev
        }
        return streak
    }

    private static func generateGrowthNote(avgMood: Double?, trend: MoodTrend, entryCount: Int) -> String {
        if entryCount == 0 { return String(localized: "recap.growth.empty") }
        switch trend {
        case .improving:
            return String(localized: "recap.growth.improving")
        case .declining:
            return String(localized: "recap.growth.declining")
        case .stable:
            if let avg = avgMood, avg >= 3.5 {
                return String(localized: "recap.growth.stablePositive")
            }
            return String(localized: "recap.growth.stableNeutral")
        case .insufficient:
            return String(localized: "recap.growth.insufficient")
        }
    }

    private static func generateActionItem(topThemes: [String], trend: MoodTrend, challenges: [String]) -> String {
        if trend == .declining && !challenges.isEmpty {
            return String(localized: "recap.action.declining")
        }
        if topThemes.contains("work") {
            return String(localized: "recap.action.work")
        }
        if topThemes.contains("self-doubt") {
            return String(localized: "recap.action.selfDoubt")
        }
        return String(localized: "recap.action.default")
    }

    /// Format recap as exportable text (for therapist sharing).
    static func formatForExport(_ recap: Recap) -> String {
        var lines: [String] = []

        lines.append("# " + String(format: String(localized: "recap.export.title"), recap.period))
        lines.append("")
        lines.append("## " + String(localized: "recap.export.overview"))
        lines.append(String(format: String(localized: "recap.export.entries"), recap.entryCount))
        lines.append(String(format: String(localized: "recap.export.words"), recap.totalWords))
        lines.append(String(format: String(localized: "recap.export.moodTrend"), recap.moodTrend.emoji, recap.moodTrend.displayName))
        lines.append(String(format: String(localized: "recap.export.streak"), recap.streakDays))

        if let avg = recap.averageMood {
            lines.append(String(format: String(localized: "recap.export.averageMood"), avg))
        }

        if !recap.topThemes.isEmpty {
            lines.append("")
            lines.append("## " + String(localized: "recap.export.topThemes"))
            lines.append(contentsOf: recap.topThemes.map { "- \($0)" })
        }

        if !recap.highlights.isEmpty {
            lines.append("")
            lines.append("## " + String(localized: "recap.highlights"))
            lines.append(contentsOf: recap.highlights.map { "- \($0)" })
        }

        if !recap.challenges.isEmpty {
            lines.append("")
            lines.append("## " + String(localized: "recap.challenges"))
            lines.append(contentsOf: recap.challenges.map { "- \($0)" })
        }

        lines.append("")
        lines.append("## " + String(localized: "recap.growth"))
        lines.append(recap.growthNote)
        lines.append("")
        lines.append("## " + String(localized: "recap.export.action"))
        lines.append(recap.actionItem)
        lines.append("")
        lines.append("---")
        lines.append("*" + String(localized: "recap.export.footer") + "*")

        return lines.joined(separator: "\n")
    }
}
