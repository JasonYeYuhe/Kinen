import SwiftUI

struct EntryRow: View {
    let entry: JournalEntry
    var highlightText: String = ""

    var body: some View {
        HStack(spacing: 12) {
            // Mood indicator
            if let mood = entry.mood {
                Text(mood.emoji)
                    .font(.title2)
            } else {
                Circle()
                    .fill(.gray.opacity(0.3))
                    .frame(width: 28, height: 28)
                    .overlay {
                        Image(systemName: "face.dashed")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.displayTitle)
                    .font(.headline)
                    .lineLimit(1)

                highlightedText(entry.preview)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    Text(entry.createdAt, style: .time)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)

                    if entry.wordCount > 0 {
                        Text("\(entry.wordCount) \(String(localized: "general.words"))")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }

                    if !entry.safeTags.isEmpty {
                        HStack(spacing: 2) {
                            ForEach(entry.safeTags.prefix(3)) { tag in
                                Text(tag.name)
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(tag.color.opacity(0.15))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }

            Spacer()

            if entry.isBookmarked {
                Image(systemName: "bookmark.fill")
                    .foregroundStyle(.purple)
                    .font(.caption)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(entryAccessibilityLabel)
    }

    private func highlightedText(_ text: String) -> Text {
        guard !highlightText.isEmpty else { return Text(text) }
        let lower = text.lowercased()
        let searchLower = highlightText.lowercased()
        guard let range = lower.range(of: searchLower) else { return Text(text) }

        let before = String(text[text.startIndex..<range.lowerBound])
        let match = String(text[range])
        let after = String(text[range.upperBound...])

        return Text(before) + Text(match).bold().foregroundColor(.purple) + Text(after)
    }

    private var entryAccessibilityLabel: String {
        var parts: [String] = []
        if let mood = entry.mood { parts.append(mood.label) }
        parts.append(entry.displayTitle)
        parts.append(entry.createdAt.formatted(date: .abbreviated, time: .shortened))
        if entry.wordCount > 0 { parts.append("\(entry.wordCount) \(String(localized: "general.words"))") }
        if entry.isBookmarked { parts.append(String(localized: "filter.bookmarked")) }
        return parts.joined(separator: ", ")
    }
}
