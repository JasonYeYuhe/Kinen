import SwiftUI
import SwiftData

struct RecapScreen: View {
    @Query(sort: \JournalEntry.createdAt, order: .reverse) private var entries: [JournalEntry]
    @State private var recapType: RecapType = .weekly

    enum RecapType: String, CaseIterable {
        case weekly = "This Week"
        case monthly = "This Month"
    }

    private var recap: RecapGenerator.Recap {
        switch recapType {
        case .weekly: RecapGenerator.weeklyRecap(entries: entries, weekOf: Date())
        case .monthly: RecapGenerator.monthlyRecap(entries: entries, monthOf: Date())
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Period picker
                    Picker("Period", selection: $recapType) {
                        ForEach(RecapType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    if recap.entryCount == 0 {
                        ContentUnavailableView {
                            Label("No Entries", systemImage: "doc.text")
                        } description: {
                            Text("Write some entries this \(recapType == .weekly ? "week" : "month") to see your recap")
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
            .navigationTitle("Recap")
        }
    }

    // MARK: - Cards

    private var overviewCard: some View {
        HStack(spacing: 16) {
            VStack(spacing: 4) {
                Text("\(recap.entryCount)")
                    .font(.system(size: 36, weight: .bold))
                Text("entries")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)

            Divider().frame(height: 50)

            VStack(spacing: 4) {
                Text("\(recap.totalWords)")
                    .font(.system(size: 36, weight: .bold))
                Text("words")
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
                Text("day streak")
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
        recapCard(title: "Mood", icon: "face.smiling") {
            if let avg = recap.averageMood {
                let mood = Mood(rawValue: Int(avg.rounded())) ?? .neutral
                HStack(spacing: 8) {
                    Text(mood.emoji).font(.title)
                    Text("Average: \(mood.label)")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(String(format: "%.1f", avg) + "/5")
                        .font(.headline)
                        .foregroundStyle(mood.color)
                }
            }
            if !recap.topEmotions.isEmpty {
                HStack(spacing: 8) {
                    Text("Top feelings:")
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
        recapCard(title: "Themes", icon: "tag") {
            if recap.topThemes.isEmpty {
                Text("No themes detected yet")
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
        recapCard(title: "Highlights", icon: "sun.max") {
            if recap.highlights.isEmpty {
                Text("Write more positive entries to see highlights")
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
        recapCard(title: "Challenges", icon: "cloud.rain") {
            if recap.challenges.isEmpty {
                Text("No major challenges detected — great!")
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
        recapCard(title: "Growth Note", icon: "leaf") {
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
            Label("Copy Recap to Clipboard", systemImage: "doc.on.clipboard")
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
