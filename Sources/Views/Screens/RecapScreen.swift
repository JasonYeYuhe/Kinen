import SwiftUI
import SwiftData

struct RecapScreen: View {
    @Query(sort: \JournalEntry.createdAt, order: .reverse) private var entries: [JournalEntry]
    @State private var recapType: RecapType = .weekly

    enum RecapType: String, CaseIterable {
        case weekly, monthly

        var label: String {
            switch self {
            case .weekly: String(localized: "recap.thisWeek")
            case .monthly: String(localized: "recap.thisMonth")
            }
        }
    }

    private var recap: RecapGenerator.Recap {
        switch recapType {
        case .weekly: RecapGenerator.weeklyRecap(entries: entries, weekOf: Date())
        case .monthly: RecapGenerator.monthlyRecap(entries: entries, monthOf: Date())
        }
    }

    var body: some View {
        ProGate(feature: String(localized: "recap.proFeature")) {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Period picker
                    Picker(String(localized: "recap.period"), selection: $recapType) {
                        ForEach(RecapType.allCases, id: \.self) { type in
                            Text(type.label).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    if recap.entryCount == 0 {
                        ContentUnavailableView {
                            Label(String(localized: "recap.empty.title"), systemImage: "doc.text")
                        } description: {
                            Text(String(localized: "recap.empty"))
                        }
                    } else {
                        overviewCard
                        moodTrendCard
                        themesCard
                        highlightsCard
                        challengesCard
                        growthCard
                        exportCard
                    }
                }
                .padding()
            }
            .navigationTitle(String(localized: "recap.title"))
        }
        } // ProGate
    }

    // MARK: - Cards

    private var overviewCard: some View {
        HStack(spacing: 16) {
            VStack(spacing: 4) {
                Text("\(recap.entryCount)")
                    .font(.system(size: 36, weight: .bold))
                Text(String(localized: "general.entries"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)

            Divider().frame(height: 50)

            VStack(spacing: 4) {
                Text("\(recap.totalWords)")
                    .font(.system(size: 36, weight: .bold))
                Text(String(localized: "general.words"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)

            Divider().frame(height: 50)

            VStack(spacing: 4) {
                Text("\(recap.moodTrend.emoji)")
                    .font(.system(size: 36))
                Text(recap.moodTrend.rawValue)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)

            Divider().frame(height: 50)

            VStack(spacing: 4) {
                Text("\(recap.streakDays)")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(.orange)
                Text(String(localized: "recap.dayStreak"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var moodTrendCard: some View {
        recapCard(title: String(localized: "recap.mood"), icon: "face.smiling") {
            if let avg = recap.averageMood {
                let mood = Mood(rawValue: Int(avg.rounded())) ?? .neutral
                HStack(spacing: 8) {
                    Text(mood.emoji).font(.title)
                    Text(String(format: String(localized: "recap.average"), mood.label))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(String(format: "%.1f", avg) + "/5")
                        .font(.headline)
                        .foregroundStyle(mood.color)
                }
            }
            if !recap.topEmotions.isEmpty {
                HStack(spacing: 8) {
                    Text(String(localized: "recap.topFeelings"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    ForEach(recap.topEmotions, id: \.self) { emotion in
                        Text(emotion)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(.purple.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }

    private var themesCard: some View {
        recapCard(title: String(localized: "recap.themes"), icon: "tag") {
            if recap.topThemes.isEmpty {
                Text(String(localized: "recap.themes.empty"))
                    .foregroundStyle(.secondary)
            } else {
                FlowLayout(spacing: 6) {
                    ForEach(recap.topThemes, id: \.self) { theme in
                        Text(theme)
                            .font(.callout)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.purple.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }

    private var highlightsCard: some View {
        recapCard(title: String(localized: "recap.highlights"), icon: "sun.max") {
            if recap.highlights.isEmpty {
                Text(String(localized: "recap.highlights.empty"))
                    .foregroundStyle(.secondary)
            } else {
                ForEach(recap.highlights, id: \.self) { highlight in
                    HStack(alignment: .top, spacing: 8) {
                        Text("✨")
                        Text(highlight)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var challengesCard: some View {
        recapCard(title: String(localized: "recap.challenges"), icon: "cloud.rain") {
            if recap.challenges.isEmpty {
                Text(String(localized: "recap.challenges.empty"))
                    .foregroundStyle(.secondary)
            } else {
                ForEach(recap.challenges, id: \.self) { challenge in
                    HStack(alignment: .top, spacing: 8) {
                        Text("💪")
                        Text(challenge)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var growthCard: some View {
        recapCard(title: String(localized: "recap.growth"), icon: "leaf") {
            Text(recap.growthNote)
                .font(.body)
                .foregroundStyle(.secondary)

            Divider()

            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(.yellow)
                Text(recap.actionItem)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
        }
    }

    private var exportCard: some View {
        Button(action: {
            let text = RecapGenerator.formatForExport(recap)
            #if os(macOS)
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(text, forType: .string)
            #else
            UIPasteboard.general.string = text
            #endif
        }) {
            Label(String(localized: "recap.copy"), systemImage: "doc.on.clipboard")
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        }
        .buttonStyle(.bordered)
        .tint(.purple)
    }

    // MARK: - Card Template

    private func recapCard<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.headline)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
