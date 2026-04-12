import SwiftUI
import SwiftData

/// "Chat with your Journal" — ask natural language questions about your entries.
struct JournalChatScreen: View {
    @Query(sort: \JournalEntry.createdAt, order: .reverse) private var entries: [JournalEntry]
    @State private var query = ""
    @State private var messages: [ChatMessage] = []
    @State private var isSearching = false

    struct ChatMessage: Identifiable {
        let id = UUID()
        let isUser: Bool
        let text: String
        let results: [SemanticSearch.SearchResult]?

        init(isUser: Bool, text: String, results: [SemanticSearch.SearchResult]? = nil) {
            self.isUser = isUser
            self.text = text
            self.results = results
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Chat messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        // Welcome message
                        if messages.isEmpty {
                            welcomeView
                        }

                        ForEach(messages) { message in
                            chatBubble(message)
                                .id(message.id)
                        }

                        if isSearching {
                            HStack(spacing: 8) {
                                ProgressView().controlSize(.small)
                                Text(String(localized: "chat.thinking"))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.leading, 16)
                        }
                    }
                    .padding()
                }
                .onChange(of: messages.count) {
                    if let last = messages.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
            }

            Divider()

            // Input bar
            HStack(spacing: 8) {
                TextField(String(localized: "chat.placeholder"), text: $query)
                    .textFieldStyle(.plain)
                    .onSubmit { sendQuery() }

                Button(action: sendQuery) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.purple)
                }
                .disabled(query.trimmingCharacters(in: .whitespaces).isEmpty || isSearching)
                .buttonStyle(.borderless)
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
        .navigationTitle(String(localized: "chat.title"))
        .navigationDestination(for: JournalEntry.self) { entry in
            EntryDetailScreen(entry: entry)
        }
    }

    // MARK: - Welcome

    private var welcomeView: some View {
        VStack(spacing: 12) {
            Image(systemName: "bubble.left.and.text.bubble.right")
                .font(.system(size: 40))
                .foregroundStyle(.purple)

            Text(String(localized: "chat.welcome.title"))
                .font(.headline)

            Text(String(localized: "chat.welcome.description"))
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 6) {
                suggestionChip("What made me happiest this month?")
                suggestionChip("Show entries about work")
                suggestionChip("When did I feel most grateful?")
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }

    private func suggestionChip(_ text: String) -> some View {
        Button {
            query = text
            sendQuery()
        } label: {
            Text(text)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.purple.opacity(0.1))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Chat Bubble

    @ViewBuilder
    private func chatBubble(_ message: ChatMessage) -> some View {
        if message.isUser {
            HStack {
                Spacer()
                Text(message.text)
                    .font(.subheadline)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.purple)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        } else {
            VStack(alignment: .leading, spacing: 8) {
                Text(message.text)
                    .font(.subheadline)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                // Show matched entries if any
                if let results = message.results, !results.isEmpty {
                    ForEach(results.prefix(3)) { result in
                        NavigationLink(value: result.entry) {
                            HStack(spacing: 8) {
                                if let mood = result.entry.mood {
                                    Text(mood.emoji)
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(result.entry.displayTitle)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                    Text(result.entry.preview)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                                Spacer()
                                Text(result.entry.createdAt, style: .date)
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(8)
                            .background(.purple.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Send Query

    private func sendQuery() {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        messages.append(ChatMessage(isUser: true, text: trimmed))
        query = ""
        isSearching = true

        Task {
            // Try to answer as a question first
            if let answer = SemanticSearch.answerQuestion(trimmed, entries: entries) {
                let results = SemanticSearch.search(query: trimmed, in: entries, limit: 3)
                messages.append(ChatMessage(isUser: false, text: answer, results: results))
            } else {
                // Fall back to semantic search
                let results = SemanticSearch.search(query: trimmed, in: entries, limit: 5)
                if results.isEmpty {
                    messages.append(ChatMessage(isUser: false, text: String(localized: "chat.noResults")))
                } else {
                    let count = results.count
                    messages.append(ChatMessage(
                        isUser: false,
                        text: String(format: String(localized: "chat.found.%lld"), count),
                        results: results
                    ))
                }
            }
            isSearching = false
        }
    }
}
