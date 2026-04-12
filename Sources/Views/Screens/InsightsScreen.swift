import SwiftUI
import SwiftData
import Charts

struct InsightsScreen: View {
    @Query(sort: \JournalEntry.createdAt, order: .reverse) private var entries: [JournalEntry]
    @State private var chartRange: ChartRange = .week
    @State private var appeared = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    streakCard.cardAppear(appeared, delay: 0)
                    moodChartCard.cardAppear(appeared, delay: 0.05)
                    weeklyStatsCard.cardAppear(appeared, delay: 0.1)
                    sentimentTrendCard.cardAppear(appeared, delay: 0.15)
                    writingActivityCard.cardAppear(appeared, delay: 0.2)
                    topTagsCard.cardAppear(appeared, delay: 0.25)

                    // Smart Insights
                    smartInsightsSection.cardAppear(appeared, delay: 0.3)

                    // Link to Recap
                    NavigationLink(destination: RecapScreen()) {
                        HStack {
                            Label(String(localized: "insights.viewRecap"), systemImage: "doc.text.magnifyingglass")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(.purple.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
                .padding()
            }
            .navigationTitle("Insights")
            .onAppear { withAnimation(.easeOut(duration: 0.4)) { appeared = true } }
        }
    }

    // MARK: - Streak Card

    private var streakCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Label(String(localized: "insights.streak"), systemImage: "flame.fill")
                    .font(.subheadline)
                    .foregroundStyle(.orange)
                Text("\(currentStreak)")
                    .font(.system(size: 48, weight: .bold))
                Text(currentStreak == 1 ? String(localized: "general.day") : String(localized: "general.days"))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Label(String(localized: "insights.totalEntries"), systemImage: "book.closed.fill")
                    .font(.subheadline)
                    .foregroundStyle(.purple)
                Text("\(entries.count)")
                    .font(.system(size: 48, weight: .bold))
                Text(String(localized: "general.entries"))
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(localized: "insights.streak") + " \(currentStreak) " + (currentStreak == 1 ? String(localized: "general.day") : String(localized: "general.days")) + ", " + String(localized: "insights.totalEntries") + " \(entries.count)")
    }

    // MARK: - Mood Chart (Swift Charts)

    private var moodChartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(String(localized: "insights.moodTrend"))
                    .font(.headline)
                Spacer()
                Picker("Range", selection: $chartRange) {
                    ForEach(ChartRange.allCases) { range in
                        Text(range.label).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 200)
            }

            if moodChartData.isEmpty {
                Text(String(localized: "insights.moodTrend.empty"))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                Chart(moodChartData) { point in
                    LineMark(
                        x: .value("Date", point.date, unit: .day),
                        y: .value("Mood", point.value)
                    )
                    .foregroundStyle(.purple.gradient)
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value("Date", point.date, unit: .day),
                        y: .value("Mood", point.value)
                    )
                    .foregroundStyle(.purple.opacity(0.1).gradient)
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Date", point.date, unit: .day),
                        y: .value("Mood", point.value)
                    )
                    .foregroundStyle(moodColor(for: point.value))
                    .symbolSize(30)
                }
                .chartYScale(domain: 1...5)
                .chartYAxis {
                    AxisMarks(values: [1, 2, 3, 4, 5]) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let v = value.as(Int.self), let mood = Mood(rawValue: v) {
                                Text(mood.emoji)
                            }
                        }
                    }
                }
                .frame(height: 180)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Sentiment Trend

    private var sentimentTrendCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "insights.sentiment"))
                .font(.headline)

            if sentimentData.isEmpty {
                Text(String(localized: "insights.sentiment.empty"))
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 12)
            } else {
                Chart(sentimentData) { point in
                    BarMark(
                        x: .value("Date", point.date, unit: .day),
                        y: .value("Sentiment", point.value)
                    )
                    .foregroundStyle(point.value >= 0 ? Color.green.gradient : Color.red.gradient)
                    .cornerRadius(2)
                }
                .chartYScale(domain: -1...1)
                .frame(height: 120)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Writing Activity Heatmap

    private var writingActivityCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "insights.activity"))
                .font(.headline)

            HStack(spacing: 3) {
                ForEach(last30DaysActivity, id: \.date) { day in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(activityColor(count: day.count))
                        .frame(width: 12, height: 12)
                        .help("\(day.date.shortDate): \(day.count) entries")
                }
            }

            HStack(spacing: 12) {
                Label(String(format: String(localized: "insights.wordsMonth"), totalWordsThisMonth), systemImage: "character.cursor.ibeam")
                Spacer()
                Label(String(format: String(localized: "insights.avgPerEntry"), averageWordsPerEntry), systemImage: "doc.text")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Weekly Stats

    private var weeklyStatsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "insights.thisWeek"))
                .font(.headline)

            let weekEntries = entries.filter {
                Calendar.current.isDate($0.createdAt, equalTo: Date(), toGranularity: .weekOfYear)
            }

            HStack(spacing: 20) {
                StatItem(value: "\(weekEntries.count)", label: String(localized: "insights.entries"), icon: "doc.text", color: .blue)
                StatItem(value: "\(weekEntries.reduce(0) { $0 + $1.wordCount })", label: String(localized: "insights.words"), icon: "character.cursor.ibeam", color: .green)
                StatItem(value: averageMoodEmoji(for: weekEntries), label: String(localized: "insights.avgMood"), icon: "face.smiling", color: .purple)
                StatItem(value: totalWritingTime(for: weekEntries), label: String(localized: "insights.time"), icon: "timer", color: .orange)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Top Tags

    private var topTagsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "insights.topTopics"))
                .font(.headline)

            let tagCounts = Dictionary(grouping: entries.flatMap { $0.safeTags }) { $0.name }
                .mapValues { $0.count }
                .sorted { $0.value > $1.value }
                .prefix(10)

            if tagCounts.isEmpty {
                Text(String(localized: "insights.topTopics.empty"))
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

    // MARK: - Smart Insights

    @ViewBuilder
    private var smartInsightsSection: some View {
        let smartInsights = InsightEngine.generateInsights(from: entries)
        if !smartInsights.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Label(String(localized: "insights.smart"), systemImage: "sparkles")
                    .font(.headline)
                    .foregroundStyle(.purple)

                ForEach(smartInsights.prefix(4)) { insight in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: insight.icon)
                            .foregroundStyle(.purple)
                            .font(.subheadline)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(insight.title)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text(insight.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.purple.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: - Data Models

    struct ChartPoint: Identifiable {
        let id = UUID()
        let date: Date
        let value: Double
    }

    enum ChartRange: String, CaseIterable, Identifiable {
        case week = "7D"
        case month = "30D"
        case quarter = "90D"
        var id: String { rawValue }
        var label: String { rawValue }
        var days: Int {
            switch self {
            case .week: 7
            case .month: 30
            case .quarter: 90
            }
        }
    }

    // MARK: - Computed Data

    private var moodChartData: [ChartPoint] {
        let calendar = Calendar.current
        let cutoff = Date.daysAgo(chartRange.days)
        let rangeEntries = entries.filter { $0.createdAt >= cutoff }

        let grouped = Dictionary(grouping: rangeEntries) { calendar.startOfDay(for: $0.createdAt) }
        return grouped.compactMap { date, dayEntries in
            let moods = dayEntries.compactMap { $0.mood }
            guard !moods.isEmpty else { return nil }
            let avg = Double(moods.map { $0.rawValue }.reduce(0, +)) / Double(moods.count)
            return ChartPoint(date: date, value: avg)
        }.sorted { $0.date < $1.date }
    }

    private var sentimentData: [ChartPoint] {
        let cutoff = Date.daysAgo(chartRange.days)
        return entries
            .filter { $0.createdAt >= cutoff && $0.sentimentScore != nil }
            .map { ChartPoint(date: $0.createdAt, value: $0.sentimentScore!) }
            .sorted { $0.date < $1.date }
    }

    struct DayActivity: Identifiable {
        let id = UUID()
        let date: Date
        let count: Int
    }

    private var last30DaysActivity: [DayActivity] {
        let calendar = Calendar.current
        return (0..<30).reversed().map { daysAgo in
            let date = calendar.startOfDay(for: Date.daysAgo(daysAgo))
            let count = entries.filter { calendar.isDate($0.createdAt, inSameDayAs: date) }.count
            return DayActivity(date: date, count: count)
        }
    }

    private var currentStreak: Int {
        let calendar = Calendar.current
        let dates = Set(entries.map { calendar.startOfDay(for: $0.createdAt) })
        return Date().startOfDay.consecutiveDays(in: dates)
    }

    private var totalWordsThisMonth: Int {
        let startOfMonth = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Date()))!
        return entries.filter { $0.createdAt >= startOfMonth }.reduce(0) { $0 + $1.wordCount }
    }

    private var averageWordsPerEntry: Int {
        guard !entries.isEmpty else { return 0 }
        return entries.reduce(0) { $0 + $1.wordCount } / entries.count
    }

    // MARK: - Helpers

    private func moodColor(for value: Double) -> Color {
        switch Int(value.rounded()) {
        case 1: .red
        case 2: .orange
        case 3: .gray
        case 4: .green
        case 5: .purple
        default: .gray
        }
    }

    private func activityColor(count: Int) -> Color {
        switch count {
        case 0: Color.secondary.opacity(0.1)
        case 1: Color.purple.opacity(0.3)
        case 2: Color.purple.opacity(0.5)
        default: Color.purple.opacity(0.8)
        }
    }

    private func averageMoodEmoji(for entries: [JournalEntry]) -> String {
        let moods = entries.compactMap { $0.mood }
        guard !moods.isEmpty else { return "—" }
        let avg = Double(moods.map { $0.rawValue }.reduce(0, +)) / Double(moods.count)
        return Mood(rawValue: Int(avg.rounded()))?.emoji ?? "😐"
    }

    private func totalWritingTime(for entries: [JournalEntry]) -> String {
        let total = entries.reduce(0.0) { $0 + $1.writingDuration }
        return total.formattedDuration
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

// MARK: - Card Appear Animation

private extension View {
    func cardAppear(_ appeared: Bool, delay: Double) -> some View {
        self
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)
            .animation(.easeOut(duration: 0.4).delay(delay), value: appeared)
    }
}
