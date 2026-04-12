import WidgetKit
import SwiftUI

// MARK: - Streak Widget

struct StreakEntry: TimelineEntry {
    let date: Date
    let currentStreak: Int
    let totalEntries: Int
}

struct StreakProvider: TimelineProvider {
    func placeholder(in context: Context) -> StreakEntry {
        StreakEntry(date: Date(), currentStreak: 7, totalEntries: 42)
    }

    func getSnapshot(in context: Context, completion: @escaping (StreakEntry) -> Void) {
        let data = WidgetDataProvider.loadData()
        completion(StreakEntry(date: Date(), currentStreak: data.streak, totalEntries: data.totalEntries))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StreakEntry>) -> Void) {
        let data = WidgetDataProvider.loadData()
        let entry = StreakEntry(date: Date(), currentStreak: data.streak, totalEntries: data.totalEntries)
        // Refresh at midnight
        let midnight = Calendar.current.startOfDay(for: Date().addingTimeInterval(86400))
        let timeline = Timeline(entries: [entry], policy: .after(midnight))
        completion(timeline)
    }
}

struct StreakWidgetView: View {
    var entry: StreakEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            smallView
        default:
            mediumView
        }
    }

    private var smallView: some View {
        VStack(spacing: 8) {
            Image(systemName: "flame.fill")
                .font(.title)
                .foregroundStyle(.orange)

            Text("\(entry.currentStreak)")
                .font(.system(size: 42, weight: .bold))

            Text(entry.currentStreak == 1 ? "day" : "days")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private var mediumView: some View {
        HStack(spacing: 20) {
            VStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.title2)
                    .foregroundStyle(.orange)
                Text("\(entry.currentStreak)")
                    .font(.system(size: 36, weight: .bold))
                Text("day streak")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            VStack(spacing: 4) {
                Image(systemName: "book.closed.fill")
                    .font(.title2)
                    .foregroundStyle(.purple)
                Text("\(entry.totalEntries)")
                    .font(.system(size: 36, weight: .bold))
                Text("entries")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct StreakWidget: Widget {
    let kind = "StreakWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StreakProvider()) { entry in
            StreakWidgetView(entry: entry)
        }
        .configurationDisplayName("Journaling Streak")
        .description("Track your consecutive journaling days.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
