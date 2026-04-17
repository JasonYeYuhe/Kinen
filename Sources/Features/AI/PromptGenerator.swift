import Foundation
import SwiftData

/// Generates contextual writing prompts based on mood, history, and patterns.
/// All generation is local — no network calls.
struct PromptGenerator {

    private static var fallbackPrompt: String { String(localized: "prompt.fallback") }

    /// Generate a writing prompt based on current context.
    static func generatePrompt(
        currentMood: Mood?,
        recentEntries: [JournalEntry],
        today: Date = Date()
    ) -> String {
        // Priority: mood-based > historical > general
        if let mood = currentMood {
            return moodBasedPrompt(mood: mood)
        }

        if let historicalPrompt = historicalPrompt(entries: recentEntries, today: today) {
            return historicalPrompt
        }

        return generalPrompts.randomElement() ?? fallbackPrompt
    }

    /// Generate multiple prompt suggestions.
    static func generatePrompts(
        currentMood: Mood?,
        recentEntries: [JournalEntry],
        count: Int = 3
    ) -> [String] {
        var prompts: [String] = []

        if let mood = currentMood {
            prompts.append(moodBasedPrompt(mood: mood))
        }

        // Add gratitude prompt
        if let p = gratitudePrompts.randomElement() { prompts.append(p) }

        // Add reflection prompt
        if let p = reflectionPrompts.randomElement() { prompts.append(p) }

        // Add CBT prompt if recent entries show negative sentiment
        let recentSentiment = recentEntries.prefix(3).compactMap { $0.sentimentScore }
        let avgSentiment = recentSentiment.isEmpty ? 0 : recentSentiment.reduce(0, +) / Double(recentSentiment.count)
        if avgSentiment < -0.2 {
            if let p = cbtPrompts.randomElement() { prompts.append(p) }
        }

        return Array(prompts.prefix(count))
    }

    // MARK: - Mood-Based Prompts

    private static func moodBasedPrompt(mood: Mood) -> String {
        let prompts: [String]
        switch mood {
        case .great: prompts = greatMoodPrompts
        case .good: prompts = goodMoodPrompts
        case .neutral: prompts = neutralMoodPrompts
        case .bad: prompts = badMoodPrompts
        case .terrible: prompts = terribleMoodPrompts
        }
        return prompts.randomElement() ?? fallbackPrompt
    }

    // MARK: - Historical Prompts

    private static func historicalPrompt(entries: [JournalEntry], today: Date) -> String? {
        let calendar = Calendar.current

        // "One year ago today..."
        if let oneYearAgo = calendar.date(byAdding: .year, value: -1, to: today),
           let yearOldEntry = entries.first(where: { calendar.isDate($0.createdAt, inSameDayAs: oneYearAgo) }) {
            return String(format: String(localized: "prompt.historical.yearAgo"), yearOldEntry.preview)
        }

        // "One month ago..."
        if let oneMonthAgo = calendar.date(byAdding: .month, value: -1, to: today),
           let monthOldEntry = entries.first(where: { calendar.isDate($0.createdAt, inSameDayAs: oneMonthAgo) }) {
            return String(format: String(localized: "prompt.historical.monthAgo"), monthOldEntry.preview)
        }

        return nil
    }

    // MARK: - Prompt Libraries

    private static var greatMoodPrompts: [String] {[
        String(localized: "prompt.great.1"),
        String(localized: "prompt.great.2"),
        String(localized: "prompt.great.3"),
        String(localized: "prompt.great.4"),
    ]}

    private static var goodMoodPrompts: [String] {[
        String(localized: "prompt.good.1"),
        String(localized: "prompt.good.2"),
        String(localized: "prompt.good.3"),
        String(localized: "prompt.good.4"),
    ]}

    private static var neutralMoodPrompts: [String] {[
        String(localized: "prompt.neutral.1"),
        String(localized: "prompt.neutral.2"),
        String(localized: "prompt.neutral.3"),
        String(localized: "prompt.neutral.4"),
    ]}

    private static var badMoodPrompts: [String] {[
        String(localized: "prompt.bad.1"),
        String(localized: "prompt.bad.2"),
        String(localized: "prompt.bad.3"),
        String(localized: "prompt.bad.4"),
    ]}

    private static var terribleMoodPrompts: [String] {[
        String(localized: "prompt.terrible.1"),
        String(localized: "prompt.terrible.2"),
        String(localized: "prompt.terrible.3"),
        String(localized: "prompt.terrible.4"),
    ]}

    private static var gratitudePrompts: [String] {[
        String(localized: "prompt.gratitude.1"),
        String(localized: "prompt.gratitude.2"),
        String(localized: "prompt.gratitude.3"),
        String(localized: "prompt.gratitude.4"),
    ]}

    private static var reflectionPrompts: [String] {[
        String(localized: "prompt.reflection.1"),
        String(localized: "prompt.reflection.2"),
        String(localized: "prompt.reflection.3"),
        String(localized: "prompt.reflection.4"),
    ]}

    private static var cbtPrompts: [String] {[
        String(localized: "prompt.cbt.1"),
        String(localized: "prompt.cbt.2"),
        String(localized: "prompt.cbt.3"),
        String(localized: "prompt.cbt.4"),
    ]}

    private static var generalPrompts: [String] {[
        String(localized: "prompt.general.1"),
        String(localized: "prompt.general.2"),
        String(localized: "prompt.general.3"),
        String(localized: "prompt.general.4"),
    ]}
}
