import SwiftUI
import SwiftData

struct JournalListScreen: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \JournalEntry.createdAt, order: .reverse) private var entries: [JournalEntry]
    @Binding var selectedEntry: JournalEntry?
    @State private var showingEditor = false
    @State private var searchText = ""

    // Filter state
    @State private var selectedMoods: Set<Mood> = []
    @State private var selectedTags: Set<String> = []
    @State private var dateRange: DateRange = .all
    @State private var bookmarkedOnly = false

    private var filteredEntries: [JournalEntry] {
        var result = entries

        // Text search (coexists with filters — Gemini recommendation)
        if !searchText.isEmpty {
            result = result.filter {
                $0.content.localizedCaseInsensitiveContains(searchText) ||
                ($0.title?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }

        // Mood filter
        if !selectedMoods.isEmpty {
            result = result.filter { entry in
                guard let mood = entry.mood else { return false }
                return selectedMoods.contains(mood)
            }
        }

        // Tag filter
        if !selectedTags.isEmpty {
            result = result.filter { entry in
                entry.safeTags.contains { selectedTags.contains($0.name) }
            }
        }

        // Date range
        if let start = dateRange.startDate {
            result = result.filter { $0.createdAt >= start }
        }

        // Bookmarked only
        if bookmarkedOnly {
            result = result.filter { $0.isBookmarked }
        }

        return result
    }

    var body: some View {
        VStack(spacing: 0) {
            // Filter bar
            FilterBar(
                selectedMoods: $selectedMoods,
                selectedTags: $selectedTags,
                dateRange: $dateRange,
                bookmarkedOnly: $bookmarkedOnly
            )

            Divider()

            // Entry list
            List(selection: $selectedEntry) {
                ForEach(groupedByDate, id: \.key) { date, dayEntries in
                    Section(header: Text(date, style: .date)) {
                        ForEach(dayEntries) { entry in
                            NavigationLink(value: entry) {
                                EntryRow(entry: entry)
                            }
                            .tag(entry)
                        }
                        .onDelete { offsets in
                            deleteEntries(dayEntries: dayEntries, at: offsets)
                        }
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search entries...")
        .navigationTitle("Journal (\(filteredEntries.count))")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingEditor = true }) {
                    Label("New Entry", systemImage: "square.and.pencil")
                }
                .keyboardShortcut("n", modifiers: .command)
            }
        }
        .sheet(isPresented: $showingEditor) {
            EntryEditorSheet(entry: nil)
        }
        .navigationDestination(for: JournalEntry.self) { entry in
            EntryDetailScreen(entry: entry)
        }
        .overlay {
            if entries.isEmpty {
                ContentUnavailableView {
                    Label("No Entries Yet", systemImage: "book.closed")
                } description: {
                    Text("Tap + to write your first journal entry")
                } actions: {
                    Button("Write Now") { showingEditor = true }
                        .buttonStyle(.borderedProminent)
                        .tint(.purple)
                }
            }
        }
    }

    private var groupedByDate: [(key: Date, value: [JournalEntry])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredEntries) { entry in
            calendar.startOfDay(for: entry.createdAt)
        }
        return grouped.sorted { $0.key > $1.key }
    }

    private func deleteEntries(dayEntries: [JournalEntry], at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(dayEntries[index])
        }
    }
}
