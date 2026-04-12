import WidgetKit
import SwiftUI

// MARK: - Mood Trend Widget

struct MoodEntry: TimelineEntry {
    let date: Date
    let recentMoods: [(date: Date, value: Double)]
    let averageMood: String
}

struct MoodProvider: TimelineProvider {
    func placeholder(in context: Context) -> MoodEntry {
        MoodEntry(date: Date(), recentMoods: [], averageMood: "😐")
    }

    func getSnapshot(in context: Context, completion: @escaping (MoodEntry) -> Void) {
        let data = WidgetDataProvider.loadData()
        completion(MoodEntry(date: Date(), recentMoods: data.recentMoods, averageMood: data.averageMoodEmoji))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MoodEntry>) -> Void) {
        let data = WidgetDataProvider.loadData()
        let entry = MoodEntry(date: Date(), recentMoods: data.recentMoods, averageMood: data.averageMoodEmoji)
        let midnight = Calendar.current.startOfDay(for: Date().addingTimeInterval(86400))
        let timeline = Timeline(entries: [entry], policy: .after(midnight))
        completion(timeline)
    }
}

struct MoodWidgetView: View {
    var entry: MoodEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Mood This Week")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(entry.averageMood)
                    .font(.title3)
            }

            if entry.recentMoods.isEmpty {
                Text("Start journaling to see your mood trend")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            } else {
                // Simple mini bar chart
                HStack(alignment: .bottom, spacing: 3) {
                    ForEach(entry.recentMoods.suffix(7), id: \.date) { mood in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(moodColor(mood.value))
                            .frame(height: max(CGFloat(mood.value) * 30, 4))
                    }
                }
                .frame(height: 30)
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private func moodColor(_ value: Double) -> Color {
        // value is 0.0-1.0 normalized; map to 1-5 mood scale
        switch Int((value * 4).rounded()) + 1 {
        case 1: .red
        case 2: .orange
        case 3: .gray
        case 4: .green
        case 5: .purple
        default: .gray
        }
    }
}

struct MoodWidget: Widget {
    let kind = "MoodWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MoodProvider()) { entry in
            MoodWidgetView(entry: entry)
        }
        .configurationDisplayName("Mood Trend")
        .description("See your mood at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
