import SwiftUI
import SwiftData

/// Horizontal filter bar for journal entries: mood, tags, date, bookmarks.
/// Coexists with full-text search (Gemini recommendation).
struct FilterBar: View {
    @Query(sort: \Tag.name) private var allTags: [Tag]

    @Binding var selectedMoods: Set<Mood>
    @Binding var selectedTags: Set<String>
    @Binding var dateRange: DateRange
    @Binding var bookmarkedOnly: Bool

    var isActive: Bool {
        !selectedMoods.isEmpty || !selectedTags.isEmpty || dateRange != .all || bookmarkedOnly
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Clear all
                if isActive {
                    Button(action: clearAll) {
                        Label("Clear", systemImage: "xmark.circle.fill")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }

                // Mood filter chips
                ForEach(Mood.allCases) { mood in
                    FilterChip(
                        label: mood.emoji,
                        isSelected: selectedMoods.contains(mood),
                        action: { toggleMood(mood) }
                    )
                }

                Divider().frame(height: 20)

                // Bookmark filter
                FilterChip(
                    label: String(localized: "filter.bookmarked"),
                    icon: "bookmark.fill",
                    isSelected: bookmarkedOnly,
                    action: { bookmarkedOnly.toggle() }
                )

                // Date range
                Menu {
                    ForEach(DateRange.allCases) { range in
                        Button(action: { dateRange = range }) {
                            if dateRange == range {
                                Label(range.label, systemImage: "checkmark")
                            } else {
                                Text(range.label)
                            }
                        }
                    }
                } label: {
                    FilterChip(
                        label: dateRange.label,
                        icon: "calendar",
                        isSelected: dateRange != .all,
                        action: {}
                    )
                }

                Divider().frame(height: 20)

                // Tag chips (top 8)
                let topTags = allTags.sorted { $0.entryCount > $1.entryCount }.prefix(8)
                ForEach(Array(topTags)) { tag in
                    FilterChip(
                        label: tag.name,
                        isSelected: selectedTags.contains(tag.name),
                        color: tag.color,
                        action: { toggleTag(tag.name) }
                    )
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 6)
        }
    }

    private func toggleMood(_ mood: Mood) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if selectedMoods.contains(mood) {
                selectedMoods.remove(mood)
            } else {
                selectedMoods.insert(mood)
            }
        }
        HapticManager.selection()
    }

    private func toggleTag(_ name: String) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if selectedTags.contains(name) {
                selectedTags.remove(name)
            } else {
                selectedTags.insert(name)
            }
        }
        HapticManager.selection()
    }

    private func clearAll() {
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedMoods.removeAll()
            selectedTags.removeAll()
            dateRange = .all
            bookmarkedOnly = false
        }
        HapticManager.impact(.light)
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let label: String
    var icon: String? = nil
    let isSelected: Bool
    var color: Color = .purple
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 10))
                }
                Text(label)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isSelected ? color.opacity(0.2) : Color.secondary.opacity(0.08))
            .foregroundStyle(isSelected ? color : .secondary)
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(isSelected ? color.opacity(0.5) : .clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityValue(isSelected ? String(localized: "accessibility.selected") : "")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Date Range

enum DateRange: String, CaseIterable, Identifiable {
    case all, today, week, month, quarter

    var id: String { rawValue }
    var label: String {
        switch self {
        case .all: String(localized: "filter.allTime")
        case .today: String(localized: "filter.today")
        case .week: String(localized: "filter.thisWeek")
        case .month: String(localized: "filter.thisMonth")
        case .quarter: String(localized: "filter.3months")
        }
    }

    var startDate: Date? {
        let calendar = Calendar.current
        switch self {
        case .all: return nil
        case .today: return calendar.startOfDay(for: Date())
        case .week: return calendar.dateInterval(of: .weekOfYear, for: Date())?.start
        case .month: return calendar.date(from: calendar.dateComponents([.year, .month], from: Date()))
        case .quarter: return calendar.date(byAdding: .month, value: -3, to: Date())
        }
    }
}
