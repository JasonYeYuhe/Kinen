import Foundation
import SwiftData
import OSLog

private let logger = Logger(subsystem: "com.kinen.app", category: "RecapGenerator")

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
    }

    /// Generate a weekly recap for the given week.
    static func weeklyRecap(entries: [JournalEntry], weekOf: Date) -> Recap {
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: weekOf)?.start ?? weekOf
        let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek)!

        let weekEntries = entries.filter { $0.createdAt >= startOfWeek && $0.createdAt < endOfWeek }
            .sorted { $0.createdAt < $1.createdAt }

        return generateRecap(
            entries: weekEntries,
            period: "Week of \(startOfWeek.formatted(.dateTime.month().day()))",
            allEntries: entries
        )
    }

    /// Generate a monthly recap.
    static func monthlyRecap(entries: [JournalEntry], monthOf: Date) -> Recap {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: monthOf)
        let startOfMonth = calendar.date(from: components)!
        let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!

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
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
        }
        return streak
    }

    private static func generateGrowthNote(avgMood: Double?, trend: MoodTrend, entryCount: Int) -> String {
        if entryCount == 0 { return "Start writing to unlock your personal growth insights." }
        switch trend {
        case .improving:
            return "Your mood has been trending upward. You're building positive momentum — keep going!"
        case .declining:
            return "It's been a tough stretch. Remember that acknowledging difficult feelings is a sign of emotional intelligence, not weakness."
        case .stable:
            if let avg = avgMood, avg >= 3.5 {
                return "You've maintained a consistently positive outlook. What's working well for you?"
            }
            return "Consistency is powerful. Even on neutral days, showing up for yourself through journaling matters."
        case .insufficient:
            return "Write a few more entries this week and I'll start showing you personalized patterns."
        }
    }

    private static func generateActionItem(topThemes: [String], trend: MoodTrend, challenges: [String]) -> String {
        if trend == .declining && !challenges.isEmpty {
            return "This week, try the CBT Three-Column template when difficult thoughts come up. It can help shift perspective."
        }
        if topThemes.contains("work") {
            return "Work has been a major theme. Consider setting one work boundary this week."
        }
        if topThemes.contains("self-doubt") {
            return "Self-doubt appeared in your entries. Try listing 3 recent accomplishments, no matter how small."
        }
        return "Keep your journaling streak going! Consistency builds self-awareness."
    }

    /// Format recap as exportable text (for therapist sharing).
    static func formatForExport(_ recap: Recap) -> String {
        var text = """
        # Kinen Journal Recap: \(recap.period)

        ## Overview
        - Entries: \(recap.entryCount)
        - Total words: \(recap.totalWords)
        - Mood trend: \(recap.moodTrend.emoji) \(recap.moodTrend.rawValue)
        - Journaling streak: \(recap.streakDays) days
        """

        if let avg = recap.averageMood {
            text += "\n- Average mood: \(String(format: "%.1f", avg))/5"
        }

        if !recap.topThemes.isEmpty {
            text += "\n\n## Top Themes\n" + recap.topThemes.map { "- \($0)" }.joined(separator: "\n")
        }

        if !recap.highlights.isEmpty {
            text += "\n\n## Highlights\n" + recap.highlights.map { "- \($0)" }.joined(separator: "\n")
        }

        if !recap.challenges.isEmpty {
            text += "\n\n## Challenges\n" + recap.challenges.map { "- \($0)" }.joined(separator: "\n")
        }

        text += "\n\n## Growth Note\n\(recap.growthNote)"
        text += "\n\n## Suggested Action\n\(recap.actionItem)"
        text += "\n\n---\n*Generated by Kinen — all analysis performed on-device*"

        return text
    }
}
