import SwiftUI

struct EntryDetailScreen: View {
    @Environment(\.modelContext) private var modelContext
    let entry: JournalEntry
    @State private var showingEditor = false
    @State private var isReanalyzing = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header: mood + date
                HStack {
                    if let mood = entry.mood {
                        HStack(spacing: 6) {
                            Text(mood.emoji)
                                .font(.title)
                            Text(mood.label)
                                .font(.subheadline)
                                .foregroundStyle(mood.color)
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(entry.createdAt, style: .date)
                            .font(.subheadline)
                        Text(entry.createdAt, style: .time)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // Metadata badges
                HStack(spacing: 8) {
                    if let score = entry.sentimentScore {
                        SentimentBadge(score: score)
                    }
                    if let location = entry.location {
                        MetadataBadge(icon: "location.fill", text: location, color: .blue)
                    }
                    if let weather = entry.weather {
                        MetadataBadge(icon: "cloud.sun.fill", text: weather, color: .orange)
                    }
                }

                Divider()

                // Content
                MarkdownText(content: entry.content)
                    .font(.body)
                    .lineSpacing(4)

                // Tags
                if !entry.safeTags.isEmpty {
                    Divider()
                    FlowLayout(spacing: 6) {
                        ForEach(entry.safeTags) { tag in
                            Text(tag.name)
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(tag.color.opacity(0.15))
                                .clipShape(Capsule())
                        }
                    }
                }

                // AI Insights
                if !entry.safeInsights.isEmpty {
                    Divider()
                    VStack(alignment: .leading, spacing: 8) {
                        Label(String(localized: "detail.aiInsights"), systemImage: "sparkles")
                            .font(.headline)
                            .foregroundStyle(.purple)

                        ForEach(entry.safeInsights) { insight in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: insight.type.icon)
                                    .foregroundStyle(.purple)
                                    .font(.caption)
                                    .frame(width: 20)
                                Text(insight.content)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Spacer(minLength: 40)
            }
            .padding()
        }
        .navigationTitle(entry.displayTitle)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingEditor = true }) {
                    Label("Edit", systemImage: "pencil")
                }
            }
            ToolbarItem {
                Button(action: {
                    entry.isBookmarked.toggle()
                }) {
                    Label("Bookmark",
                          systemImage: entry.isBookmarked ? "bookmark.fill" : "bookmark")
                }
            }
            ToolbarItem {
                Button(action: { reanalyze() }) {
                    if isReanalyzing {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Label("Re-analyze", systemImage: "sparkles")
                    }
                }
                .disabled(isReanalyzing)
                .help("Re-run AI analysis on this entry")
            }
        }
        .sheet(isPresented: $showingEditor) {
            EntryEditorSheet(entry: entry)
        }
    }

    private func reanalyze() {
        isReanalyzing = true
        // Clear old insights
        entry.insights = []
        entry.sentimentScore = nil

        Task {
            await AIJournalingLoop.shared.processEntry(entry, in: modelContext)
            isReanalyzing = false
        }
    }
}

// MARK: - Supporting Views

struct SentimentBadge: View {
    let score: Double

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
            Text(label)
                .font(.caption)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .foregroundStyle(color)
        .clipShape(Capsule())
        .accessibilityLabel(String(localized: "accessibility.sentiment") + " " + label)
    }

    private var label: String {
        if score > 0.3 { return String(localized: "sentiment.positive") }
        if score < -0.3 { return String(localized: "sentiment.negative") }
        return String(localized: "sentiment.neutral")
    }

    private var icon: String {
        if score > 0.3 { return "arrow.up.right" }
        if score < -0.3 { return "arrow.down.right" }
        return "arrow.right"
    }

    private var color: Color {
        if score > 0.3 { return .green }
        if score < -0.3 { return .red }
        return .gray
    }
}

struct MetadataBadge: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(text)
                .font(.caption)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .foregroundStyle(color)
        .clipShape(Capsule())
    }
}

extension InsightType {
    var icon: String {
        switch self {
        case .sentiment: "heart.text.square"
        case .pattern: "waveform.path.ecg"
        case .suggestion: "lightbulb"
        case .topicExtraction: "tag"
        case .streak: "flame"
        }
    }
}

// MARK: - Simple FlowLayout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), positions)
    }
}
