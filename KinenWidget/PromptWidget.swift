import WidgetKit
import SwiftUI

// MARK: - Daily Prompt Widget

struct PromptEntry: TimelineEntry {
    let date: Date
    let prompt: String
}

struct PromptProvider: TimelineProvider {
    private let prompts = [
        "What made you smile today?",
        "What's on your mind right now?",
        "What are you grateful for today?",
        "What was the best part of your day?",
        "What did you learn today?",
        "How are you really feeling?",
        "What's one thing you want to remember about today?",
        "What challenged you today?",
        "What gave you energy today?",
        "What would make tomorrow great?",
    ]

    func placeholder(in context: Context) -> PromptEntry {
        PromptEntry(date: Date(), prompt: "What made you smile today?")
    }

    func getSnapshot(in context: Context, completion: @escaping (PromptEntry) -> Void) {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        let prompt = prompts[dayOfYear % prompts.count]
        completion(PromptEntry(date: Date(), prompt: prompt))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PromptEntry>) -> Void) {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        let prompt = prompts[dayOfYear % prompts.count]
        let entry = PromptEntry(date: Date(), prompt: prompt)
        let midnight = Calendar.current.startOfDay(for: Date().addingTimeInterval(86400))
        let timeline = Timeline(entries: [entry], policy: .after(midnight))
        completion(timeline)
    }
}

struct PromptWidgetView: View {
    var entry: PromptEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(.purple)
                Text("Daily Prompt")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.purple)
            }

            Text(entry.prompt)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(3)

            Spacer(minLength: 0)

            Text("Tap to write")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct PromptWidget: Widget {
    let kind = "PromptWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PromptProvider()) { entry in
            PromptWidgetView(entry: entry)
        }
        .configurationDisplayName("Writing Prompt")
        .description("Get a daily journaling prompt.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
