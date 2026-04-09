import Foundation
import SwiftUI

/// Built-in journal templates with structured prompts.
/// Each template provides a guided writing experience.
enum JournalTemplate: String, Codable, CaseIterable, Identifiable {
    case freeWrite
    case dailyReview
    case gratitude
    case morningPages
    case cbtThreeColumn
    case dreamJournal
    case goalReflection
    case weeklyReview

    var id: String { rawValue }

    var name: String {
        switch self {
        case .freeWrite: String(localized: "Free Write")
        case .dailyReview: String(localized: "Daily Review")
        case .gratitude: String(localized: "Gratitude Journal")
        case .morningPages: String(localized: "Morning Pages")
        case .cbtThreeColumn: String(localized: "CBT Reflection")
        case .dreamJournal: String(localized: "Dream Journal")
        case .goalReflection: String(localized: "Goal Reflection")
        case .weeklyReview: String(localized: "Weekly Review")
        }
    }

    var icon: String {
        switch self {
        case .freeWrite: "pencil.line"
        case .dailyReview: "sun.and.horizon"
        case .gratitude: "heart.fill"
        case .morningPages: "sunrise"
        case .cbtThreeColumn: "brain.head.profile"
        case .dreamJournal: "moon.stars"
        case .goalReflection: "target"
        case .weeklyReview: "calendar.badge.checkmark"
        }
    }

    var color: Color {
        switch self {
        case .freeWrite: .blue
        case .dailyReview: .orange
        case .gratitude: .pink
        case .morningPages: .yellow
        case .cbtThreeColumn: .purple
        case .dreamJournal: .indigo
        case .goalReflection: .green
        case .weeklyReview: .teal
        }
    }

    var description: String {
        switch self {
        case .freeWrite: String(localized: "Write freely without any prompts or structure")
        case .dailyReview: String(localized: "Reflect on your day: highlights, challenges, and lessons")
        case .gratitude: String(localized: "Focus on things you're grateful for today")
        case .morningPages: String(localized: "Stream of consciousness writing to start your day")
        case .cbtThreeColumn: String(localized: "Identify situations, thoughts, and rational responses")
        case .dreamJournal: String(localized: "Record and reflect on your dreams")
        case .goalReflection: String(localized: "Track progress toward your goals and intentions")
        case .weeklyReview: String(localized: "Review the past week and plan ahead")
        }
    }

    /// Template prompts that guide the writing experience.
    /// Returns an array of section prompts the user fills in.
    var prompts: [TemplatePrompt] {
        switch self {
        case .freeWrite:
            return [TemplatePrompt(title: nil, placeholder: String(localized: "Start writing..."))]

        case .dailyReview:
            return [
                TemplatePrompt(title: String(localized: "Best moment today"), placeholder: String(localized: "What was the highlight of your day?")),
                TemplatePrompt(title: String(localized: "Challenge"), placeholder: String(localized: "What was difficult today?")),
                TemplatePrompt(title: String(localized: "Lesson learned"), placeholder: String(localized: "What did today teach you?")),
                TemplatePrompt(title: String(localized: "Tomorrow"), placeholder: String(localized: "What's one thing you want to do tomorrow?"))
            ]

        case .gratitude:
            return [
                TemplatePrompt(title: "1️⃣", placeholder: String(localized: "Something that made you smile today...")),
                TemplatePrompt(title: "2️⃣", placeholder: String(localized: "A person you're grateful for...")),
                TemplatePrompt(title: "3️⃣", placeholder: String(localized: "A small thing you often take for granted...")),
                TemplatePrompt(title: String(localized: "Why it matters"), placeholder: String(localized: "How do these things make your life better?"))
            ]

        case .morningPages:
            return [TemplatePrompt(title: nil, placeholder: String(localized: "Write whatever comes to mind. Don't stop, don't edit, just let it flow..."))]

        case .cbtThreeColumn:
            return [
                TemplatePrompt(title: String(localized: "Situation"), placeholder: String(localized: "What happened? Describe the event objectively.")),
                TemplatePrompt(title: String(localized: "Automatic Thought"), placeholder: String(localized: "What went through your mind? What did you tell yourself?")),
                TemplatePrompt(title: String(localized: "Rational Response"), placeholder: String(localized: "Is there another way to see this? What would you tell a friend?")),
                TemplatePrompt(title: String(localized: "How do you feel now?"), placeholder: String(localized: "Has your perspective shifted?"))
            ]

        case .dreamJournal:
            return [
                TemplatePrompt(title: String(localized: "The Dream"), placeholder: String(localized: "Describe what you remember...")),
                TemplatePrompt(title: String(localized: "Emotions"), placeholder: String(localized: "How did the dream make you feel?")),
                TemplatePrompt(title: String(localized: "Symbols"), placeholder: String(localized: "Any recurring themes, people, or symbols?")),
                TemplatePrompt(title: String(localized: "Connection"), placeholder: String(localized: "Does this relate to anything in your waking life?"))
            ]

        case .goalReflection:
            return [
                TemplatePrompt(title: String(localized: "Current Goal"), placeholder: String(localized: "What are you working toward?")),
                TemplatePrompt(title: String(localized: "Progress"), placeholder: String(localized: "What steps did you take today?")),
                TemplatePrompt(title: String(localized: "Obstacles"), placeholder: String(localized: "What's getting in your way?")),
                TemplatePrompt(title: String(localized: "Next Step"), placeholder: String(localized: "What's one small action you can take next?"))
            ]

        case .weeklyReview:
            return [
                TemplatePrompt(title: String(localized: "Wins"), placeholder: String(localized: "What went well this week?")),
                TemplatePrompt(title: String(localized: "Challenges"), placeholder: String(localized: "What was hard this week?")),
                TemplatePrompt(title: String(localized: "Insights"), placeholder: String(localized: "What did you learn about yourself?")),
                TemplatePrompt(title: String(localized: "Next Week"), placeholder: String(localized: "What do you want to focus on?"))
            ]
        }
    }
}

struct TemplatePrompt: Identifiable {
    let id = UUID()
    let title: String?
    let placeholder: String
}
