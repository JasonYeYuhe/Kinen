import Foundation
import OSLog

private let logger = Logger(subsystem: "com.jasonye.kinen", category: "TherapistHandoff")

/// Aggregates journal entries into a structured HandoffReport suitable for
/// sharing with a clinician. All processing is on-device and pure: same input,
/// same output, no I/O.
enum TherapistHandoffService {

    /// Build a HandoffReport from the entries that fall within `range`.
    /// `entries` may be unsorted and may include entries outside the range —
    /// the service filters internally.
    /// `sections` selects which optional sections to populate; unselected
    /// sections come back empty.
    static func buildReport(
        from entries: [JournalEntry],
        range: HandoffReport.DateRange,
        userTopics: String = "",
        sections: HandoffReport.Sections = .all,
        now: Date = Date()
    ) -> HandoffReport {
        let scoped = entries
            .filter { $0.createdAt >= range.start && $0.createdAt <= range.end }
            .sorted { $0.createdAt < $1.createdAt }

        let overview = sections.overview
            ? buildOverview(scoped)
            : HandoffReport.Overview(totalEntries: 0, totalWords: 0, averageMood: nil, averageSentiment: nil, highestMoodDay: nil, lowestMoodDay: nil, writingDays: 0, longestSilence: 0)

        let moodTrend = sections.moodTrend
            ? scoped.compactMap { entry -> HandoffReport.MoodPoint? in
                guard let mood = entry.mood else { return nil }
                return HandoffReport.MoodPoint(date: entry.createdAt, mood: mood.rawValue)
            }
            : []

        let topThemes = sections.topThemes ? buildThemes(scoped) : []
        let distortions = sections.cognitiveDistortions ? buildDistortions(scoped) : []
        let highlights = sections.highlightedEntries ? buildHighlights(scoped) : []
        let crisis = sections.crisisFlags ? buildCrisisFlags(scoped) : []

        logger.info("Built handoff report: entries=\(scoped.count), themes=\(topThemes.count), distortions=\(distortions.count), highlights=\(highlights.count), crisis=\(crisis.count)")

        return HandoffReport(
            generatedAt: now,
            dateRange: range,
            overview: overview,
            moodTrend: moodTrend,
            topThemes: topThemes,
            cognitiveDistortions: distortions,
            highlightedEntries: highlights,
            crisisFlags: crisis,
            userTopics: userTopics.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }

    // MARK: - Overview

    static func buildOverview(_ entries: [JournalEntry]) -> HandoffReport.Overview {
        let totalWords = entries.reduce(0) { $0 + $1.wordCount }

        let moodValues = entries.compactMap { $0.mood?.rawValue }
        let avgMood: Double? = moodValues.isEmpty
            ? nil
            : Double(moodValues.reduce(0, +)) / Double(moodValues.count)

        let sentiments = entries.compactMap { $0.sentimentScore }
        let avgSentiment: Double? = sentiments.isEmpty
            ? nil
            : sentiments.reduce(0, +) / Double(sentiments.count)

        let moodEntries = entries.filter { $0.mood != nil }
        let highestMoodDay = moodEntries.max { ($0.mood?.rawValue ?? 0) < ($1.mood?.rawValue ?? 0) }?.createdAt
        let lowestMoodDay = moodEntries.min { ($0.mood?.rawValue ?? 0) < ($1.mood?.rawValue ?? 0) }?.createdAt

        let calendar = Calendar.current
        let writingDays = Set(entries.map { calendar.startOfDay(for: $0.createdAt) }).count

        // Longest gap (in days) between consecutive entries
        let sortedDates = entries.map(\.createdAt).sorted()
        var longestSilence = 0
        if sortedDates.count >= 2 {
            for i in 1..<sortedDates.count {
                let days = calendar.dateComponents([.day], from: sortedDates[i - 1], to: sortedDates[i]).day ?? 0
                if days > longestSilence { longestSilence = days }
            }
        }

        return HandoffReport.Overview(
            totalEntries: entries.count,
            totalWords: totalWords,
            averageMood: avgMood,
            averageSentiment: avgSentiment,
            highestMoodDay: highestMoodDay,
            lowestMoodDay: lowestMoodDay,
            writingDays: writingDays,
            longestSilence: longestSilence
        )
    }

    // MARK: - Themes

    static func buildThemes(_ entries: [JournalEntry], limit: Int = 5) -> [HandoffReport.Theme] {
        // Aggregate tag frequencies (tags include AI-generated topics from SentimentAnalyzer).
        var counts: [String: Int] = [:]
        for entry in entries {
            for tag in entry.safeTags {
                counts[tag.name, default: 0] += 1
            }
        }
        return counts
            .sorted { lhs, rhs in
                if lhs.value != rhs.value { return lhs.value > rhs.value }
                return lhs.key < rhs.key
            }
            .prefix(limit)
            .map { HandoffReport.Theme(name: $0.key, count: $0.value) }
    }

    // MARK: - CBT Distortions

    static func buildDistortions(_ entries: [JournalEntry]) -> [HandoffReport.DistortionStat] {
        var stats: [String: (count: Int, example: String?)] = [:]

        for entry in entries {
            let detected = CBTReflection.analyze(entry.content)
            // Only count each distortion once per entry to avoid double-weighting long entries.
            var seen: Set<String> = []
            for d in detected {
                let name = d.type.rawValue
                guard !seen.contains(name) else { continue }
                seen.insert(name)
                let prior = stats[name] ?? (0, nil)
                let example = prior.example ?? d.triggerText
                stats[name] = (prior.count + 1, example)
            }
        }

        return stats
            .sorted { lhs, rhs in
                if lhs.value.count != rhs.value.count { return lhs.value.count > rhs.value.count }
                return lhs.key < rhs.key
            }
            .map { HandoffReport.DistortionStat(name: $0.key, count: $0.value.count, exampleSentence: $0.value.example) }
    }

    // MARK: - Highlighted Entries

    /// Pick a small set of representative entries:
    ///   - any user-pinned entries in range (capped at 3)
    ///   - the lowest-mood entry
    ///   - the highest-mood entry
    ///   - up to 2 entries with sentiment furthest from average
    /// Duplicates are removed, capped at 6 total.
    static func buildHighlights(_ entries: [JournalEntry], limit: Int = 6) -> [HandoffReport.HighlightedEntry] {
        var picked: [(JournalEntry, HandoffReport.HighlightedEntry.HighlightReason)] = []
        var seenIDs: Set<UUID> = []

        func add(_ entry: JournalEntry, reason: HandoffReport.HighlightedEntry.HighlightReason) {
            guard !seenIDs.contains(entry.id) else { return }
            seenIDs.insert(entry.id)
            picked.append((entry, reason))
        }

        // Pinned (user explicit signal)
        for entry in entries.filter({ $0.isPinned }).prefix(3) {
            add(entry, reason: .userPinned)
        }

        // Highest / lowest mood
        let moodEntries = entries.filter { $0.mood != nil }
        if let highest = moodEntries.max(by: { ($0.mood?.rawValue ?? 0) < ($1.mood?.rawValue ?? 0) }) {
            add(highest, reason: .highestMood)
        }
        if let lowest = moodEntries.min(by: { ($0.mood?.rawValue ?? 0) < ($1.mood?.rawValue ?? 0) }) {
            add(lowest, reason: .lowestMood)
        }

        // Largest sentiment deviation
        let sentimentEntries = entries.filter { $0.sentimentScore != nil }
        if !sentimentEntries.isEmpty {
            let avg = sentimentEntries.compactMap(\.sentimentScore).reduce(0, +) / Double(sentimentEntries.count)
            let byDeviation = sentimentEntries.sorted {
                abs(($0.sentimentScore ?? 0) - avg) > abs(($1.sentimentScore ?? 0) - avg)
            }
            for entry in byDeviation.prefix(2) {
                add(entry, reason: .largestDeviation)
            }
        }

        return picked
            .prefix(limit)
            .map { (entry, reason) in
                HandoffReport.HighlightedEntry(
                    date: entry.createdAt,
                    title: entry.title,
                    mood: entry.mood?.rawValue,
                    sentiment: entry.sentimentScore,
                    snippet: snippet(from: entry.content),
                    reason: reason
                )
            }
    }

    // MARK: - Crisis Flags

    static func buildCrisisFlags(_ entries: [JournalEntry]) -> [HandoffReport.CrisisFlag] {
        entries.compactMap { entry in
            guard let alert = CrisisDetector.check(entry.content) else { return nil }
            let severity: String
            switch alert.severity {
            case .high: severity = "high"
            case .moderate: severity = "moderate"
            case .low: severity = "low"
            }
            return HandoffReport.CrisisFlag(
                date: entry.createdAt,
                severity: severity,
                snippet: snippet(from: entry.content, length: 200)
            )
        }
    }

    // MARK: - Helpers

    /// Sanitize entry content for display in the report:
    /// strip template markers + bold markdown, collapse whitespace, truncate.
    static func snippet(from content: String, length: Int = 280) -> String {
        var text = content
        text = text.replacingOccurrences(of: "<!--[^>]*-->", with: "", options: .regularExpression)
        text = text.replacingOccurrences(of: "\\*\\*([^*]*)\\*\\*", with: "$1", options: .regularExpression)
        text = text.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.count > length {
            return String(text.prefix(length)) + "…"
        }
        return text
    }

    // MARK: - Markdown export

    /// Render the report as a Markdown document suitable for sharing as text.
    static func renderMarkdown(_ report: HandoffReport) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none

        let datetimeFormatter = DateFormatter()
        datetimeFormatter.dateStyle = .medium
        datetimeFormatter.timeStyle = .short

        var md = ""
        md += "# Therapist Handoff — \(dateFormatter.string(from: report.dateRange.start)) – \(dateFormatter.string(from: report.dateRange.end))\n\n"
        md += "_Generated by Kinen on \(datetimeFormatter.string(from: report.generatedAt)) — all data stayed on device._\n\n"

        // Overview
        let o = report.overview
        if o.totalEntries > 0 {
            md += "## Overview\n\n"
            md += "- **Entries:** \(o.totalEntries) over \(report.dateRange.dayCount) days (\(o.writingDays) writing days)\n"
            md += "- **Total words:** \(o.totalWords)\n"
            if let avg = o.averageMood {
                md += "- **Average mood:** \(String(format: "%.2f", avg)) / 5\n"
            }
            if let s = o.averageSentiment {
                md += "- **Average sentiment:** \(String(format: "%+.2f", s)) (range: -1.0 to +1.0)\n"
            }
            if let high = o.highestMoodDay {
                md += "- **Highest mood:** \(dateFormatter.string(from: high))\n"
            }
            if let low = o.lowestMoodDay {
                md += "- **Lowest mood:** \(dateFormatter.string(from: low))\n"
            }
            if o.longestSilence > 1 {
                md += "- **Longest silence:** \(o.longestSilence) days between entries\n"
            }
            md += "\n"
        }

        // User topics
        if !report.userTopics.isEmpty {
            md += "## Topics I'd like to discuss\n\n\(report.userTopics)\n\n"
        }

        // Themes
        if !report.topThemes.isEmpty {
            md += "## Recurring themes\n\n"
            for theme in report.topThemes {
                md += "- **\(theme.name)** — \(theme.count) entries\n"
            }
            md += "\n"
        }

        // Distortions
        if !report.cognitiveDistortions.isEmpty {
            md += "## Cognitive patterns observed\n\n"
            md += "_(Best-effort detection from journal text. Not a clinical diagnosis.)_\n\n"
            for d in report.cognitiveDistortions {
                md += "- **\(d.name)** — observed in \(d.count) entries"
                if let example = d.exampleSentence {
                    md += "  \n  > \(example)"
                }
                md += "\n"
            }
            md += "\n"
        }

        // Crisis flags
        if !report.crisisFlags.isEmpty {
            md += "## ⚠️ Concerning passages\n\n"
            md += "_(Flagged by on-device crisis detection. Please review with the writer.)_\n\n"
            for flag in report.crisisFlags {
                md += "- **\(dateFormatter.string(from: flag.date))** [\(flag.severity)]  \n  > \(flag.snippet)\n"
            }
            md += "\n"
        }

        // Highlighted entries
        if !report.highlightedEntries.isEmpty {
            md += "## Selected entries\n\n"
            for entry in report.highlightedEntries {
                md += "### \(dateFormatter.string(from: entry.date))"
                if let title = entry.title, !title.isEmpty {
                    md += " — \(title)"
                }
                md += "\n"
                var meta: [String] = ["_\(reasonLabel(entry.reason))_"]
                if let mood = entry.mood {
                    meta.append("Mood: \(mood)/5")
                }
                if let s = entry.sentiment {
                    meta.append("Sentiment: \(String(format: "%+.2f", s))")
                }
                md += meta.joined(separator: " · ") + "\n\n"
                md += "> \(entry.snippet)\n\n"
            }
        }

        return md
    }

    private static func reasonLabel(_ reason: HandoffReport.HighlightedEntry.HighlightReason) -> String {
        switch reason {
        case .lowestMood: "Lowest mood in range"
        case .highestMood: "Highest mood in range"
        case .largestDeviation: "Notable sentiment shift"
        case .crisis: "Crisis flag"
        case .userPinned: "Pinned by writer"
        }
    }
}
