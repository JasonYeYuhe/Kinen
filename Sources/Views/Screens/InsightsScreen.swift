import SwiftUI
import SwiftData

struct InsightsScreen: View {
    @Query(sort: \JournalEntry.createdAt, order: .reverse) private var entries: [JournalEntry]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    streakCard
                    moodTrendCard
                    weeklyStatsCard
                    topTagsCard
                }
                .padding()
            }
            .navigationTitle("Insights")
        }
    }

    // MARK: - Streak Card

    private var streakCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Label("Current Streak", systemImage: "flame.fill")
                    .font(.subheadline)
                    .foregroundStyle(.orange)
                Text("\(currentStreak)")
                    .font(.system(size: 48, weight: .bold))
                Text(currentStreak == 1 ? "day" : "days")
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Label("Total Entries", systemImage: "book.closed.fill")
                    .font(.subheadline)
                    .foregroundStyle(.purple)
                Text("\(entries.count)")
                    .font(.system(size: 48, weight: .bold))
                Text("entries")
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Mood Trend

    private var moodTrendCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Mood Trend (Last 7 Days)")
                .font(.headline)

            if last7DaysMoods.isEmpty {
                Text("Start logging moods to see your trend")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(last7DaysMoods, id: \.date) { item in
                        VStack(spacing: 4) {
                            if let mood = item.averageMood {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(mood.color.gradient)
                                    .frame(height: CGFloat(mood.rawValue) * 20)
                                Text(mood.emoji)
                                    .font(.caption)
                            } else {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(.gray.opacity(0.2))
                                    .frame(height: 20)
                                Text("—")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Text(item.date, format: .dateTime.weekday(.abbreviated))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 120)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Weekly Stats

    private var weeklyStatsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Week")
                .font(.headline)

            let weekEntries = entries.filter {
                Calendar.current.isDate($0.createdAt, equalTo: Date(), toGranularity: .weekOfYear)
            }

            HStack(spacing: 20) {
                StatItem(value: "\(weekEntries.count)", label: "Entries", icon: "doc.text", color: .blue)
                StatItem(value: "\(weekEntries.reduce(0) { $0 + $1.wordCount })", label: "Words", icon: "character.cursor.ibeam", color: .green)
                StatItem(value: averageSentimentLabel(for: weekEntries), label: "Avg Mood", icon: "face.smiling", color: .purple)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Top Tags

    private var topTagsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Top Topics")
                .font(.headline)

            let tagCounts = Dictionary(grouping: entries.flatMap { $0.tags }) { $0.name }
                .mapValues { $0.count }
                .sorted { $0.value > $1.value }
                .prefix(8)

            if tagCounts.isEmpty {
                Text("Tags will appear as you write more")
                    .foregroundStyle(.secondary)
            } else {
                FlowLayout(spacing: 6) {
                    ForEach(Array(tagCounts), id: \.key) { name, count in
                        HStack(spacing: 4) {
                            Text(name)
                            Text("(\(count))")
                                .foregroundStyle(.secondary)
                        }
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.purple.opacity(0.1))
                        .clipShape(Capsule())
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Helpers

    private var currentStreak: Int {
        let calendar = Calendar.current
        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())

        while true {
            let hasEntry = entries.contains { calendar.isDate($0.createdAt, inSameDayAs: checkDate) }
            if hasEntry {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else {
                break
            }
        }
        return streak
    }

    private struct DayMood {
        let date: Date
        let averageMood: Mood?
    }

    private var last7DaysMoods: [DayMood] {
        let calendar = Calendar.current
        return (0..<7).reversed().map { daysAgo in
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: calendar.startOfDay(for: Date()))!
            let dayEntries = entries.filter { calendar.isDate($0.createdAt, inSameDayAs: date) }
            let moods = dayEntries.compactMap { $0.mood }
            let avgRaw = moods.isEmpty ? nil : Double(moods.map { $0.rawValue }.reduce(0, +)) / Double(moods.count)
            let avgMood = avgRaw.flatMap { Mood(rawValue: Int($0.rounded())) }
            return DayMood(date: date, averageMood: avgMood)
        }
    }

    private func averageSentimentLabel(for entries: [JournalEntry]) -> String {
        let scores = entries.compactMap { $0.sentimentScore }
        guard !scores.isEmpty else { return "—" }
        let avg = scores.reduce(0, +) / Double(scores.count)
        if avg > 0.3 { return "😊" }
        if avg < -0.3 { return "😔" }
        return "😐"
    }
}

struct StatItem: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
