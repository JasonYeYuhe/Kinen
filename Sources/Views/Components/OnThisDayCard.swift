import SwiftUI
import SwiftData

/// Shows entries from the same date in previous years/months.
struct OnThisDayCard: View {
    let entries: [JournalEntry]

    private var onThisDayEntries: [JournalEntry] {
        let calendar = Calendar.current
        let today = calendar.dateComponents([.month, .day], from: Date())
        return entries.filter { entry in
            let comp = calendar.dateComponents([.month, .day, .year], from: entry.createdAt)
            let currentYear = calendar.component(.year, from: Date())
            return comp.month == today.month && comp.day == today.day && comp.year != currentYear
        }.sorted { $0.createdAt > $1.createdAt }
    }

    var body: some View {
        if !onThisDayEntries.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Label(String(localized: "onThisDay.title"), systemImage: "clock.arrow.circlepath")
                    .font(.headline)
                    .foregroundStyle(.purple)

                ForEach(onThisDayEntries.prefix(3)) { entry in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            if let mood = entry.mood {
                                Text(mood.emoji)
                            }
                            Text(yearsAgoLabel(entry.createdAt))
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.purple)
                            Spacer()
                            Text(entry.createdAt, format: .dateTime.year())
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }

                        Text(entry.preview)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    .padding(10)
                    .background(.purple.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private func yearsAgoLabel(_ date: Date) -> String {
        let years = Calendar.current.dateComponents([.year], from: date, to: Date()).year ?? 0
        if years == 1 {
            return String(localized: "onThisDay.oneYearAgo")
        } else {
            return String(format: String(localized: "onThisDay.yearsAgo.%lld"), years)
        }
    }
}
