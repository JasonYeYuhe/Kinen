import SwiftUI
import SwiftData

struct CalendarScreen: View {
    @Query(sort: \JournalEntry.createdAt) private var entries: [JournalEntry]
    @State private var selectedDate: Date = Date()
    @State private var displayedMonth: Date = Date()
    @State private var viewMode: CalendarViewMode = .month

    enum CalendarViewMode: String, CaseIterable {
        case month = "Month"
        case year = "Year"
    }

    private var calendar: Calendar { Calendar.current }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // View mode picker
                    Picker("View", selection: $viewMode) {
                        ForEach(CalendarViewMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    if viewMode == .month {
                        calendarGrid
                        selectedDayEntries
                    } else {
                        yearHeatmap
                    }
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

    // MARK: - Year Heatmap (GitHub-style)

    private var yearHeatmap: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Year navigation
            HStack {
                Button(action: {
                    displayedMonth = calendar.date(byAdding: .year, value: -1, to: displayedMonth) ?? displayedMonth
                }) {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(.borderless)

                Text(displayedMonth, format: .dateTime.year())
                    .font(.headline)
                    .frame(maxWidth: .infinity)

                Button(action: {
                    displayedMonth = calendar.date(byAdding: .year, value: 1, to: displayedMonth) ?? displayedMonth
                }) {
                    Image(systemName: "chevron.right")
                }
                .buttonStyle(.borderless)
            }

            // Month labels
            let monthLabels = calendar.shortMonthSymbols
            HStack(spacing: 0) {
                ForEach(monthLabels, id: \.self) { month in
                    Text(month)
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Heatmap grid: 12 months x ~31 days
            let yearData = yearHeatmapData()
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 12), spacing: 2) {
                ForEach(0..<31, id: \.self) { dayIndex in
                    ForEach(0..<12, id: \.self) { monthIndex in
                        let idx = monthIndex * 31 + dayIndex
                        let cellData = idx < yearData.count ? yearData[idx] : nil
                        RoundedRectangle(cornerRadius: 2)
                            .fill(cellData?.color ?? Color.secondary.opacity(0.06))
                            .frame(height: 10)
                            .help(cellData?.tooltip ?? "")
                    }
                }
            }

            // Legend
            HStack(spacing: 4) {
                Text("Less").font(.system(size: 9)).foregroundStyle(.secondary)
                ForEach(Mood.allCases) { mood in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(mood.color.opacity(0.6))
                        .frame(width: 10, height: 10)
                }
                Text("More").font(.system(size: 9)).foregroundStyle(.secondary)
                Spacer()
                Text("\(yearEntryCount) entries this year")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    private struct HeatmapCell {
        let color: Color
        let tooltip: String
    }

    private func yearHeatmapData() -> [HeatmapCell?] {
        let year = calendar.component(.year, from: displayedMonth)
        var cells: [HeatmapCell?] = []

        for month in 1...12 {
            let daysInMonth = calendar.range(of: .day, in: .month,
                for: calendar.date(from: DateComponents(year: year, month: month))!)?.count ?? 30

            for day in 1...31 {
                if day > daysInMonth {
                    cells.append(nil)
                    continue
                }

                guard let date = calendar.date(from: DateComponents(year: year, month: month, day: day)) else {
                    cells.append(nil)
                    continue
                }

                let mood = dominantMood(for: date)
                let count = entries.filter { calendar.isDate($0.createdAt, inSameDayAs: date) }.count

                if count > 0 {
                    let color = mood?.color.opacity(0.3 + Double(min(count, 3)) * 0.2) ?? .purple.opacity(0.3)
                    let dateStr = date.formatted(date: .abbreviated, time: .omitted)
                    cells.append(HeatmapCell(color: color, tooltip: "\(dateStr): \(count) entries"))
                } else {
                    cells.append(nil)
                }
            }
        }
        return cells
    }

    private var yearEntryCount: Int {
        let year = calendar.component(.year, from: displayedMonth)
        return entries.filter { calendar.component(.year, from: $0.createdAt) == year }.count
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
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
