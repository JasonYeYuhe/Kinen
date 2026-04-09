import SwiftUI

struct EntryRow: View {
    let entry: JournalEntry

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

                Text(entry.preview)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    Text(entry.createdAt, style: .time)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)

                    if entry.wordCount > 0 {
                        Text("\(entry.wordCount) words")
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
    }
}
