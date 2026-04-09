import Foundation
import SwiftData

/// Generates contextual writing prompts based on mood, history, and patterns.
/// All generation is local — no network calls.
struct PromptGenerator {

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

        return generalPrompts.randomElement()!
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
        prompts.append(gratitudePrompts.randomElement()!)

        // Add reflection prompt
        prompts.append(reflectionPrompts.randomElement()!)

        // Add CBT prompt if recent entries show negative sentiment
        let recentSentiment = recentEntries.prefix(3).compactMap { $0.sentimentScore }
        let avgSentiment = recentSentiment.isEmpty ? 0 : recentSentiment.reduce(0, +) / Double(recentSentiment.count)
        if avgSentiment < -0.2 {
            prompts.append(cbtPrompts.randomElement()!)
        }

        return Array(prompts.prefix(count))
    }

    // MARK: - Mood-Based Prompts

    private static func moodBasedPrompt(mood: Mood) -> String {
        switch mood {
        case .great:
            return greatMoodPrompts.randomElement()!
        case .good:
            return goodMoodPrompts.randomElement()!
        case .neutral:
            return neutralMoodPrompts.randomElement()!
        case .bad:
            return badMoodPrompts.randomElement()!
        case .terrible:
            return terribleMoodPrompts.randomElement()!
        }
    }

    // MARK: - Historical Prompts

    private static func historicalPrompt(entries: [JournalEntry], today: Date) -> String? {
        let calendar = Calendar.current

        // "One year ago today..."
        let oneYearAgo = calendar.date(byAdding: .year, value: -1, to: today)!
        if let yearOldEntry = entries.first(where: { calendar.isDate($0.createdAt, inSameDayAs: oneYearAgo) }) {
            return "One year ago, you wrote about: \"\(yearOldEntry.preview)\". How have things changed since then?"
        }

        // "One month ago..."
        let oneMonthAgo = calendar.date(byAdding: .month, value: -1, to: today)!
        if let monthOldEntry = entries.first(where: { calendar.isDate($0.createdAt, inSameDayAs: oneMonthAgo) }) {
            return "A month ago, you reflected on: \"\(monthOldEntry.preview)\". Where are you with that now?"
        }

        return nil
    }

    // MARK: - Prompt Libraries

    private static let greatMoodPrompts = [
        "What made today so wonderful? Capture this feeling so you can revisit it.",
        "Who contributed to your happiness today? How might you thank them?",
        "What would you tell your future self about this moment?",
        "What habits or choices led to this great day? How can you do more of that?",
    ]

    private static let goodMoodPrompts = [
        "What's one thing that went well today that you want to remember?",
        "What are you looking forward to this week?",
        "Describe a moment today when you felt at peace.",
        "What's something you accomplished today, no matter how small?",
    ]

    private static let neutralMoodPrompts = [
        "What's on your mind right now? Sometimes the ordinary days reveal the most.",
        "If you could change one thing about today, what would it be?",
        "What's something you've been putting off that you could tackle today?",
        "Describe your surroundings right now. What do you notice?",
    ]

    private static let badMoodPrompts = [
        "What's weighing on you? Writing it down can help lighten the load.",
        "Is there something you need but haven't asked for? What would help right now?",
        "What would you tell a friend who felt the way you do right now?",
        "Can you identify one small thing that might make tomorrow a little better?",
    ]

    private static let terribleMoodPrompts = [
        "Take a deep breath. You're here, and that counts. What do you need right now?",
        "Sometimes the hardest days teach us the most. What is this day trying to show you?",
        "Write about what's hurting. You don't need to fix it, just let it out.",
        "Name three things that are still okay, even on a terrible day.",
    ]

    private static let gratitudePrompts = [
        "What's one thing you're grateful for that you usually take for granted?",
        "Who made your life a little better recently?",
        "What's a simple pleasure you enjoyed today?",
        "What ability or skill are you thankful to have?",
    ]

    private static let reflectionPrompts = [
        "What's a belief you held a year ago that you no longer hold?",
        "What's the most important lesson you've learned recently?",
        "If you could give advice to yourself from 6 months ago, what would it be?",
        "What does your ideal ordinary day look like?",
    ]

    private static let cbtPrompts = [
        "Write about a negative thought you had today. Now, what evidence exists against it?",
        "Are you 'catastrophizing' about something? What's the most likely outcome (not the worst)?",
        "Is there a pattern in what triggers your low moods? What do you notice?",
        "Challenge an 'all-or-nothing' thought: where's the middle ground?",
    ]

    private static let generalPrompts = [
        "What's one thing that surprised you today?",
        "If today had a title, what would it be?",
        "What's a question you've been sitting with lately?",
        "Describe a recent conversation that stuck with you.",
    ]
}
