import SwiftUI
import SwiftData

/// Inline tag editor with autocomplete for entry editor.
struct TagEditor: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Tag.name) private var allTags: [Tag]
    @Binding var selectedTags: [Tag]
    @State private var inputText = ""
    @State private var showSuggestions = false

    private var suggestions: [Tag] {
        guard !inputText.isEmpty else { return [] }
        let query = inputText.lowercased()
        return allTags.filter { tag in
            tag.name.contains(query) && !selectedTags.contains(where: { $0.id == tag.id })
        }.prefix(5).map { $0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Selected tags
            if !selectedTags.isEmpty {
                FlowLayout(spacing: 6) {
                    ForEach(selectedTags) { tag in
                        HStack(spacing: 4) {
                            Circle().fill(tag.color).frame(width: 6, height: 6)
                            Text(tag.name)
                                .font(.caption)
                            Button(action: { removeTag(tag) }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 8, weight: .bold))
                            }
                            .buttonStyle(.borderless)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(tag.color.opacity(0.12))
                        .clipShape(Capsule())
                    }
                }
            }

            // Input field with autocomplete
            HStack {
                Image(systemName: "tag")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("Add tag...", text: $inputText)
                    .textFieldStyle(.plain)
                    .font(.subheadline)
                    .onSubmit { addCurrentTag() }
                    .onChange(of: inputText) {
                        showSuggestions = !inputText.isEmpty && !suggestions.isEmpty
                    }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.secondary.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Autocomplete suggestions
            if showSuggestions {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(suggestions) { tag in
                        Button(action: { selectTag(tag) }) {
                            HStack {
                                Circle().fill(tag.color).frame(width: 8, height: 8)
                                Text(tag.name)
                                    .font(.subheadline)
                                Spacer()
                                Text("\(tag.entryCount)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    private func selectTag(_ tag: Tag) {
        if !selectedTags.contains(where: { $0.id == tag.id }) {
            selectedTags.append(tag)
        }
        inputText = ""
        showSuggestions = false
    }

    private func addCurrentTag() {
        let name = inputText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !name.isEmpty else { return }

        // Check if tag exists
        if let existing = allTags.first(where: { $0.name == name }) {
            selectTag(existing)
        } else {
            // Create new tag
            let newTag = Tag(name: name)
            modelContext.insert(newTag)
            selectedTags.append(newTag)
            inputText = ""
            showSuggestions = false
        }
    }

    private func removeTag(_ tag: Tag) {
        selectedTags.removeAll { $0.id == tag.id }
    }
}
