import SwiftUI
import SwiftData

struct CalendarScreen: View {
    @Query(sort: \JournalEntry.createdAt) private var entries: [JournalEntry]
    @State private var selectedDate: Date = Date()
    @State private var displayedMonth: Date = Date()

    private var calendar: Calendar { Calendar.current }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    calendarGrid
                    selectedDayEntries
                }
                .padding()
            }
            .navigationTitle("Calendar")
        }
    }

    // MARK: - Calendar Grid (Mood Heatmap)

    private var calendarGrid: some View {
        VStack(spacing: 12) {
            // Month navigation
            HStack {
                Button(action: { changeMonth(by: -1) }) {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(.borderless)

                Text(displayedMonth, format: .dateTime.year().month(.wide))
                    .font(.headline)
                    .frame(maxWidth: .infinity)

                Button(action: { changeMonth(by: 1) }) {
                    Image(systemName: "chevron.right")
                }
                .buttonStyle(.borderless)
            }

            // Weekday headers
            HStack(spacing: 4) {
                ForEach(calendar.shortWeekdaySymbols, id: \.self) { day in
                    Text(day)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Day cells
            let days = daysInMonth()
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                ForEach(days, id: \.self) { date in
                    if let date {
                        DayCell(
                            date: date,
                            mood: dominantMood(for: date),
                            hasEntry: hasEntry(on: date),
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            isToday: calendar.isDateInToday(date)
                        )
                        .onTapGesture { selectedDate = date }
                    } else {
                        Color.clear
                            .frame(height: 36)
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Selected Day Entries

    private var selectedDayEntries: some View {
        let dayEntries = entries.filter { calendar.isDate($0.createdAt, inSameDayAs: selectedDate) }

        return VStack(alignment: .leading, spacing: 8) {
            Text(selectedDate, style: .date)
                .font(.headline)

            if dayEntries.isEmpty {
                Text("No entries for this day")
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 12)
            } else {
                ForEach(dayEntries) { entry in
                    NavigationLink(value: entry) {
                        EntryRow(entry: entry)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .navigationDestination(for: JournalEntry.self) { entry in
            EntryDetailScreen(entry: entry)
        }
    }

    // MARK: - Helpers

    private func daysInMonth() -> [Date?] {
        let range = calendar.range(of: .day, in: .month, for: displayedMonth)!
        let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth))!
        let weekdayOfFirst = calendar.component(.weekday, from: firstDay) - calendar.firstWeekday
        let offset = (weekdayOfFirst + 7) % 7

        var days: [Date?] = Array(repeating: nil, count: offset)
        for day in range {
            days.append(calendar.date(byAdding: .day, value: day - 1, to: firstDay))
        }
        return days
    }

    private func changeMonth(by value: Int) {
        displayedMonth = calendar.date(byAdding: .month, value: value, to: displayedMonth) ?? displayedMonth
    }

    private func hasEntry(on date: Date) -> Bool {
        entries.contains { calendar.isDate($0.createdAt, inSameDayAs: date) }
    }

    private func dominantMood(for date: Date) -> Mood? {
        let dayEntries = entries.filter { calendar.isDate($0.createdAt, inSameDayAs: date) }
        let moods = dayEntries.compactMap { $0.mood }
        guard !moods.isEmpty else { return nil }
        let avg = Double(moods.map { $0.rawValue }.reduce(0, +)) / Double(moods.count)
        return Mood(rawValue: Int(avg.rounded()))
    }
}

struct DayCell: View {
    let date: Date
    let mood: Mood?
    let hasEntry: Bool
    let isSelected: Bool
    let isToday: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(backgroundColor)

            VStack(spacing: 1) {
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.caption)
                    .fontWeight(isToday ? .bold : .regular)
                    .foregroundStyle(isToday ? .purple : .primary)

                if hasEntry {
                    Circle()
                        .fill(mood?.color ?? .gray)
                        .frame(width: 6, height: 6)
                }
            }
        }
        .frame(height: 36)
    }

    private var backgroundColor: Color {
        if isSelected { return .purple.opacity(0.15) }
        if let mood { return mood.color.opacity(0.08) }
        return .clear
    }
}
