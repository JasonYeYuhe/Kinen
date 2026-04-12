import Foundation
import NaturalLanguage
import OSLog

/// On-device semantic search using NaturalLanguage word embeddings.
/// Enables natural language queries like "happy beach trip last summer".
/// All processing is local — no API calls, no model downloads.
struct SemanticSearch {
    private static let logger = Logger(subsystem: "com.jasonye.kinen", category: "SemanticSearch")

    struct SearchResult: Identifiable {
        let id: UUID
        let entry: JournalEntry
        let score: Double // 0.0 - 1.0, higher = more relevant
    }

    /// Search entries using semantic similarity (word embeddings).
    /// Falls back to keyword search if embeddings unavailable.
    static func search(query: String, in entries: [JournalEntry], limit: Int = 20) -> [SearchResult] {
        guard !query.isEmpty, !entries.isEmpty else { return [] }

        // Try semantic search first
        if let embedding = NLEmbedding.wordEmbedding(for: .english) {
            return semanticSearch(query: query, entries: entries, embedding: embedding, limit: limit)
        }

        // Fallback: enhanced keyword search
        return keywordSearch(query: query, entries: entries, limit: limit)
    }

    /// Answer a natural language question about journal entries.
    static func answerQuestion(_ question: String, entries: [JournalEntry]) -> String? {
        let lowered = question.lowercased()

        // Time-scoped questions
        let filteredEntries: [JournalEntry]
        if lowered.contains("this week") || lowered.contains("本周") {
            let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
            filteredEntries = entries.filter { $0.createdAt >= weekAgo }
        } else if lowered.contains("this month") || lowered.contains("本月") || lowered.contains("这个月") {
            let monthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
            filteredEntries = entries.filter { $0.createdAt >= monthAgo }
        } else if lowered.contains("last month") || lowered.contains("上个月") {
            let twoMonthsAgo = Calendar.current.date(byAdding: .month, value: -2, to: Date())!
            let oneMonthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
            filteredEntries = entries.filter { $0.createdAt >= twoMonthsAgo && $0.createdAt < oneMonthAgo }
        } else {
            filteredEntries = entries
        }

        guard !filteredEntries.isEmpty else { return nil }

        // Mood questions
        if lowered.contains("happiest") || lowered.contains("best") || lowered.contains("最开心") || lowered.contains("最好") {
            return findMoodExtreme(entries: filteredEntries, best: true)
        }
        if lowered.contains("worst") || lowered.contains("saddest") || lowered.contains("最差") || lowered.contains("最难过") {
            return findMoodExtreme(entries: filteredEntries, best: false)
        }

        // Gratitude questions
        if lowered.contains("grateful") || lowered.contains("gratitude") || lowered.contains("感恩") || lowered.contains("感激") {
            return findByTag(entries: filteredEntries, tagName: "gratitude") ??
                   findByTemplate(entries: filteredEntries, template: .gratitude)
        }

        // Topic questions — use semantic search
        let results = search(query: question, in: filteredEntries, limit: 3)
        if let top = results.first, top.score > 0.3 {
            let date = top.entry.createdAt.formatted(date: .abbreviated, time: .omitted)
            let mood = top.entry.mood?.emoji ?? ""
            return "\(mood) \(date): \(top.entry.preview)"
        }

        return nil
    }

    // MARK: - Semantic Search (Word Embeddings)

    private static func semanticSearch(query: String, entries: [JournalEntry], embedding: NLEmbedding, limit: Int) -> [SearchResult] {
        let queryWords = tokenize(query)
        guard !queryWords.isEmpty else { return keywordSearch(query: query, entries: entries, limit: limit) }

        // Get query embedding vector (average of word vectors)
        let queryVectors = queryWords.compactMap { embedding.vector(for: $0) }
        guard !queryVectors.isEmpty else { return keywordSearch(query: query, entries: entries, limit: limit) }
        let queryVector = averageVector(queryVectors)

        var results: [SearchResult] = []

        for entry in entries {
            let entryWords = tokenize(entry.content)
            let entryVectors = entryWords.prefix(100).compactMap { embedding.vector(for: $0) }
            guard !entryVectors.isEmpty else { continue }
            let entryVector = averageVector(entryVectors)

            let similarity = cosineSimilarity(queryVector, entryVector)
            // Also boost with keyword overlap
            let keywordBoost = keywordOverlapScore(query: query, content: entry.content)
            let finalScore = similarity * 0.7 + keywordBoost * 0.3

            if finalScore > 0.1 {
                results.append(SearchResult(id: entry.id, entry: entry, score: finalScore))
            }
        }

        return results.sorted { $0.score > $1.score }.prefix(limit).map { $0 }
    }

    // MARK: - Keyword Search (Fallback)

    private static func keywordSearch(query: String, entries: [JournalEntry], limit: Int) -> [SearchResult] {
        let queryWords = Set(query.lowercased().split(separator: " ").map(String.init))

        var results: [SearchResult] = []

        for entry in entries {
            let content = entry.content.lowercased()
            let title = (entry.title ?? "").lowercased()
            let combined = content + " " + title

            var score = 0.0
            for word in queryWords {
                if combined.contains(word) {
                    score += 1.0 / Double(queryWords.count)
                }
            }

            if score > 0 {
                results.append(SearchResult(id: entry.id, entry: entry, score: min(score, 1.0)))
            }
        }

        return results.sorted { $0.score > $1.score }.prefix(limit).map { $0 }
    }

    // MARK: - Question Answering Helpers

    private static func findMoodExtreme(entries: [JournalEntry], best: Bool) -> String? {
        let withMood = entries.filter { $0.mood != nil }
        guard !withMood.isEmpty else { return nil }

        let sorted = withMood.sorted {
            best ? ($0.mood!.rawValue > $1.mood!.rawValue) : ($0.mood!.rawValue < $1.mood!.rawValue)
        }
        guard let top = sorted.first else { return nil }

        let date = top.createdAt.formatted(date: .abbreviated, time: .omitted)
        let mood = top.mood?.emoji ?? ""
        return "\(mood) \(date): \(top.preview)"
    }

    private static func findByTag(entries: [JournalEntry], tagName: String) -> String? {
        let matched = entries.filter { $0.safeTags.contains { $0.name.lowercased() == tagName } }
        guard let latest = matched.first else { return nil }
        let date = latest.createdAt.formatted(date: .abbreviated, time: .omitted)
        return "\(latest.mood?.emoji ?? "") \(date): \(latest.preview)"
    }

    private static func findByTemplate(entries: [JournalEntry], template: JournalTemplate) -> String? {
        let matched = entries.filter { $0.template == template }
        guard let latest = matched.first else { return nil }
        let date = latest.createdAt.formatted(date: .abbreviated, time: .omitted)
        return "\(latest.mood?.emoji ?? "") \(date): \(latest.preview)"
    }

    // MARK: - Vector Math

    private static func tokenize(_ text: String) -> [String] {
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = text.lowercased()
        var words: [String] = []
        tokenizer.enumerateTokens(in: text.lowercased().startIndex..<text.lowercased().endIndex) { range, _ in
            let word = String(text.lowercased()[range])
            if word.count > 2 { words.append(word) }
            return true
        }
        return words
    }

    private static func averageVector(_ vectors: [[Double]]) -> [Double] {
        guard let dim = vectors.first?.count else { return [] }
        var avg = [Double](repeating: 0, count: dim)
        for v in vectors {
            for i in 0..<dim { avg[i] += v[i] }
        }
        let n = Double(vectors.count)
        return avg.map { $0 / n }
    }

    private static func cosineSimilarity(_ a: [Double], _ b: [Double]) -> Double {
        guard a.count == b.count, !a.isEmpty else { return 0 }
        var dot = 0.0, normA = 0.0, normB = 0.0
        for i in 0..<a.count {
            dot += a[i] * b[i]
            normA += a[i] * a[i]
            normB += b[i] * b[i]
        }
        let denom = sqrt(normA) * sqrt(normB)
        return denom > 0 ? dot / denom : 0
    }

    private static func keywordOverlapScore(query: String, content: String) -> Double {
        let queryWords = Set(query.lowercased().split(separator: " ").map(String.init))
        let contentLower = content.lowercased()
        let matches = queryWords.filter { contentLower.contains($0) }.count
        return Double(matches) / max(Double(queryWords.count), 1)
    }
}
