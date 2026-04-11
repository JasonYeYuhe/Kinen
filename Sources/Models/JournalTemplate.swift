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
        case .freeWrite: String(localized: "template.freeWrite")
        case .dailyReview: String(localized: "template.dailyReview")
        case .gratitude: String(localized: "template.gratitude")
        case .morningPages: String(localized: "template.morningPages")
        case .cbtThreeColumn: String(localized: "template.cbt")
        case .dreamJournal: String(localized: "template.dream")
        case .goalReflection: String(localized: "template.goal")
        case .weeklyReview: String(localized: "template.weekly")
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
            return [TemplatePrompt(id: "freeWrite-0", title: nil, placeholder: String(localized: "Start writing..."))]

        case .dailyReview:
            return [
                TemplatePrompt(id: "dailyReview-0", title: String(localized: "Best moment today"), placeholder: String(localized: "What was the highlight of your day?")),
                TemplatePrompt(id: "dailyReview-1", title: String(localized: "Challenge"), placeholder: String(localized: "What was difficult today?")),
                TemplatePrompt(id: "dailyReview-2", title: String(localized: "Lesson learned"), placeholder: String(localized: "What did today teach you?")),
                TemplatePrompt(id: "dailyReview-3", title: String(localized: "Tomorrow"), placeholder: String(localized: "What's one thing you want to do tomorrow?"))
            ]

        case .gratitude:
            return [
                TemplatePrompt(id: "gratitude-0", title: "1️⃣", placeholder: String(localized: "Something that made you smile today...")),
                TemplatePrompt(id: "gratitude-1", title: "2️⃣", placeholder: String(localized: "A person you're grateful for...")),
                TemplatePrompt(id: "gratitude-2", title: "3️⃣", placeholder: String(localized: "A small thing you often take for granted...")),
                TemplatePrompt(id: "gratitude-3", title: String(localized: "Why it matters"), placeholder: String(localized: "How do these things make your life better?"))
            ]

        case .morningPages:
            return [TemplatePrompt(id: "morningPages-0", title: nil, placeholder: String(localized: "Write whatever comes to mind. Don't stop, don't edit, just let it flow..."))]

        case .cbtThreeColumn:
            return [
                TemplatePrompt(id: "cbt-0", title: String(localized: "Situation"), placeholder: String(localized: "What happened? Describe the event objectively.")),
                TemplatePrompt(id: "cbt-1", title: String(localized: "Automatic Thought"), placeholder: String(localized: "What went through your mind? What did you tell yourself?")),
                TemplatePrompt(id: "cbt-2", title: String(localized: "Rational Response"), placeholder: String(localized: "Is there another way to see this? What would you tell a friend?")),
                TemplatePrompt(id: "cbt-3", title: String(localized: "How do you feel now?"), placeholder: String(localized: "Has your perspective shifted?"))
            ]

        case .dreamJournal:
            return [
                TemplatePrompt(id: "dream-0", title: String(localized: "The Dream"), placeholder: String(localized: "Describe what you remember...")),
                TemplatePrompt(id: "dream-1", title: String(localized: "Emotions"), placeholder: String(localized: "How did the dream make you feel?")),
                TemplatePrompt(id: "dream-2", title: String(localized: "Symbols"), placeholder: String(localized: "Any recurring themes, people, or symbols?")),
                TemplatePrompt(id: "dream-3", title: String(localized: "Connection"), placeholder: String(localized: "Does this relate to anything in your waking life?"))
            ]

        case .goalReflection:
            return [
                TemplatePrompt(id: "goal-0", title: String(localized: "Current Goal"), placeholder: String(localized: "What are you working toward?")),
                TemplatePrompt(id: "goal-1", title: String(localized: "Progress"), placeholder: String(localized: "What steps did you take today?")),
                TemplatePrompt(id: "goal-2", title: String(localized: "Obstacles"), placeholder: String(localized: "What's getting in your way?")),
                TemplatePrompt(id: "goal-3", title: String(localized: "Next Step"), placeholder: String(localized: "What's one small action you can take next?"))
            ]

        case .weeklyReview:
            return [
                TemplatePrompt(id: "weekly-0", title: String(localized: "Wins"), placeholder: String(localized: "What went well this week?")),
                TemplatePrompt(id: "weekly-1", title: String(localized: "Challenges"), placeholder: String(localized: "What was hard this week?")),
                TemplatePrompt(id: "weekly-2", title: String(localized: "Insights"), placeholder: String(localized: "What did you learn about yourself?")),
                TemplatePrompt(id: "weekly-3", title: String(localized: "Next Week"), placeholder: String(localized: "What do you want to focus on?"))
            ]
        }
    }
}

struct TemplatePrompt: Identifiable {
    let id: String
    let title: String?
    let placeholder: String
}
