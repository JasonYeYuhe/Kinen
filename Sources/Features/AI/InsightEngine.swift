import Foundation
import SwiftData
import OSLog

/// On-device insight engine that analyzes patterns across multiple entries.
/// Discovers activity-mood correlations, time-based patterns, and trends.
struct InsightEngine {
    private static let logger = Logger(subsystem: "com.jasonye.kinen", category: "InsightEngine")

    struct SmartInsight: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        let description: String
        let type: InsightCategory
    }

    enum InsightCategory {
        case tagMoodCorrelation
        case timePattern
        case streak
        case writingHabit
        case moodTrend
    }

    /// Analyze entries and generate smart insights.
    static func generateInsights(from entries: [JournalEntry]) -> [SmartInsight] {
        guard entries.count >= 5 else { return [] }

        var insights: [SmartInsight] = []

        // 1. Tag-Mood Correlation
        insights.append(contentsOf: tagMoodCorrelations(entries))

        // 2. Best/Worst day of week
        if let dayInsight = bestDayOfWeek(entries) {
            insights.append(dayInsight)
        }

        // 3. Time-of-day writing pattern
        if let timeInsight = writingTimePattern(entries) {
            insights.append(timeInsight)
        }

        // 4. Word count vs mood correlation
        if let wordInsight = wordCountMoodCorrelation(entries) {
            insights.append(wordInsight)
        }

        // 5. Consistency insight
        if let consistencyInsight = consistencyInsight(entries) {
            insights.append(consistencyInsight)
        }

        logger.info("Generated \(insights.count) smart insights from \(entries.count) entries")
        return insights
    }

    // MARK: - Tag-Mood Correlations

    private static func tagMoodCorrelations(_ entries: [JournalEntry]) -> [SmartInsight] {
        var tagMoods: [String: [Double]] = [:]

        for entry in entries {
            guard let mood = entry.mood else { continue }
            let moodVal = mood.normalizedValue
            for tag in entry.safeTags {
                tagMoods[tag.name, default: []].append(moodVal)
            }
        }

        // Calculate average mood per tag, filter to tags with enough data
        let overallAvg = entries.compactMap { $0.mood?.normalizedValue }.reduce(0, +) /
            max(Double(entries.compactMap({ $0.mood }).count), 1)

        var results: [SmartInsight] = []

        for (tag, moods) in tagMoods where moods.count >= 3 {
            let avg = moods.reduce(0, +) / Double(moods.count)
            let diff = avg - overallAvg

            if diff > 0.15 {
                results.append(SmartInsight(
                    icon: "arrow.up.heart.fill",
                    title: String(localized: "insight.tagPositive.title"),
                    description: String(localized: "insight.tagPositive.body.\(tag)"),
                    type: .tagMoodCorrelation
                ))
            } else if diff < -0.15 {
                results.append(SmartInsight(
                    icon: "heart.text.clipboard",
                    title: String(localized: "insight.tagNegative.title"),
                    description: String(localized: "insight.tagNegative.body.\(tag)"),
                    type: .tagMoodCorrelation
                ))
            }
        }

        return Array(results.prefix(2))
    }

    // MARK: - Day of Week Pattern

    private static func bestDayOfWeek(_ entries: [JournalEntry]) -> SmartInsight? {
        let calendar = Calendar.current
        var dayMoods: [Int: [Double]] = [:]

        for entry in entries {
            guard let mood = entry.mood else { continue }
            let weekday = calendar.component(.weekday, from: entry.createdAt)
            dayMoods[weekday, default: []].append(mood.normalizedValue)
        }

        guard dayMoods.count >= 3 else { return nil }

        let dayAvgs = dayMoods.mapValues { $0.reduce(0, +) / Double($0.count) }
        guard let best = dayAvgs.max(by: { $0.value < $1.value }),
              let worst = dayAvgs.min(by: { $0.value < $1.value }),
              best.value - worst.value > 0.1 else { return nil }

        let dayName = calendar.weekdaySymbols[best.key - 1]

        return SmartInsight(
            icon: "calendar.badge.checkmark",
            title: String(localized: "insight.bestDay.title"),
            description: String(localized: "insight.bestDay.body.\(dayName)"),
            type: .timePattern
        )
    }

    // MARK: - Writing Time Pattern

    private static func writingTimePattern(_ entries: [JournalEntry]) -> SmartInsight? {
        let calendar = Calendar.current
        var morningCount = 0
        var afternoonCount = 0
        var eveningCount = 0

        for entry in entries {
            let hour = calendar.component(.hour, from: entry.createdAt)
            switch hour {
            case 5..<12: morningCount += 1
            case 12..<18: afternoonCount += 1
            default: eveningCount += 1
            }
        }

        let total = entries.count
        guard total >= 7 else { return nil }

        let maxCount = max(morningCount, afternoonCount, eveningCount)
        let ratio = Double(maxCount) / Double(total)
        guard ratio > 0.5 else { return nil }

        let timeOfDay: String
        if maxCount == morningCount {
            timeOfDay = String(localized: "insight.time.morning")
        } else if maxCount == afternoonCount {
            timeOfDay = String(localized: "insight.time.afternoon")
        } else {
            timeOfDay = String(localized: "insight.time.evening")
        }

        return SmartInsight(
            icon: "clock.fill",
            title: String(localized: "insight.writingTime.title"),
            description: String(localized: "insight.writingTime.body.\(timeOfDay).\(Int(ratio * 100))"),
            type: .writingHabit
        )
    }

    // MARK: - Word Count vs Mood

    private static func wordCountMoodCorrelation(_ entries: [JournalEntry]) -> SmartInsight? {
        let entriesWithMood = entries.filter { $0.mood != nil && $0.wordCount > 0 }
        guard entriesWithMood.count >= 10 else { return nil }

        let sorted = entriesWithMood.sorted { $0.wordCount < $1.wordCount }
        let halfCount = sorted.count / 2
        let shortEntries = Array(sorted.prefix(halfCount))
        let longEntries = Array(sorted.suffix(halfCount))

        let shortAvg = shortEntries.compactMap { $0.mood?.normalizedValue }.reduce(0, +) / max(Double(shortEntries.count), 1)
        let longAvg = longEntries.compactMap { $0.mood?.normalizedValue }.reduce(0, +) / max(Double(longEntries.count), 1)

        let diff = longAvg - shortAvg
        guard abs(diff) > 0.1 else { return nil }

        if diff > 0 {
            return SmartInsight(
                icon: "text.word.spacing",
                title: String(localized: "insight.longerBetter.title"),
                description: String(localized: "insight.longerBetter.body"),
                type: .writingHabit
            )
        } else {
            return SmartInsight(
                icon: "text.word.spacing",
                title: String(localized: "insight.shorterBetter.title"),
                description: String(localized: "insight.shorterBetter.body"),
                type: .writingHabit
            )
        }
    }

    // MARK: - Consistency Insight

    private static func consistencyInsight(_ entries: [JournalEntry]) -> SmartInsight? {
        let calendar = Calendar.current
        let last30 = entries.filter { $0.createdAt >= Date.daysAgo(30) }
        let uniqueDays = Set(last30.map { calendar.startOfDay(for: $0.createdAt) }).count

        if uniqueDays >= 25 {
            return SmartInsight(
                icon: "flame.fill",
                title: String(localized: "insight.consistent.title"),
                description: String(localized: "insight.consistent.body.\(uniqueDays)"),
                type: .streak
            )
        } else if uniqueDays <= 5 && entries.count >= 10 {
            return SmartInsight(
                icon: "bell.badge",
                title: String(localized: "insight.inconsistent.title"),
                description: String(localized: "insight.inconsistent.body"),
                type: .streak
            )
        }

        return nil
    }
}
