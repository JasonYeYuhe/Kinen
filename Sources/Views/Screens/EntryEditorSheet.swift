import SwiftUI
import SwiftData

struct EntryEditorSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let entry: JournalEntry? // nil = new entry

    @State private var content: String
    @State private var title: String
    @State private var mood: Mood?
    @State private var isAnalyzing: Bool = false

    init(entry: JournalEntry?) {
        self.entry = entry
        _content = State(initialValue: entry?.content ?? "")
        _title = State(initialValue: entry?.title ?? "")
        _mood = State(initialValue: entry?.mood)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Title
                    TextField("Title (optional)", text: $title)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .textFieldStyle(.plain)

                    // Mood picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("How are you feeling?")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        MoodPicker(selectedMood: $mood)
                    }

                    Divider()

                    // Content editor
                    TextEditor(text: $content)
                        .font(.body)
                        .frame(minHeight: 200)
                        .scrollContentBackground(.hidden)

                    // Word count
                    HStack {
                        Spacer()
                        Text("\(content.split(separator: " ").count) words")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding()
            }
            .navigationTitle(entry == nil ? "New Entry" : "Edit Entry")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 500, minHeight: 400)
        #endif
    }

    private func save() {
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedContent.isEmpty else { return }

        if let entry {
            // Update existing
            entry.content = trimmedContent
            entry.title = title.isEmpty ? nil : title
            entry.mood = mood
            entry.updatedAt = Date()
            entry.wordCount = trimmedContent.split(separator: " ").count
        } else {
            // Create new
            let newEntry = JournalEntry(
                content: trimmedContent,
                title: title.isEmpty ? nil : title,
                mood: mood
            )
            modelContext.insert(newEntry)

            // Trigger AI analysis in background
            Task {
                await SentimentAnalyzer.shared.analyze(entry: newEntry, in: modelContext)
            }
        }

        dismiss()
    }
}
