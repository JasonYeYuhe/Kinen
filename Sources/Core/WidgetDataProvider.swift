import Foundation
import SwiftData
import WidgetKit

/// Provides data to widgets via App Group shared container.
struct WidgetDataProvider {
    static let appGroupId = "group.com.jasonye.kinen"

    struct WidgetData {
        var streak: Int = 0
        var totalEntries: Int = 0
        var recentMoods: [(date: Date, value: Double)] = []
        var averageMoodEmoji: String = "😐"
    }

    static func loadData() -> WidgetData {
        guard let defaults = UserDefaults(suiteName: appGroupId) else {
            return WidgetData()
        }

        var data = WidgetData()
        data.streak = defaults.integer(forKey: "widget.streak")
        data.totalEntries = defaults.integer(forKey: "widget.totalEntries")
        data.averageMoodEmoji = defaults.string(forKey: "widget.averageMoodEmoji") ?? "😐"

        // Decode recent moods
        if let moodData = defaults.data(forKey: "widget.recentMoods"),
           let decoded = try? JSONDecoder().decode([[String: Double]].self, from: moodData) {
            data.recentMoods = decoded.compactMap { dict in
                guard let timestamp = dict["date"], let value = dict["value"] else { return nil }
                return (date: Date(timeIntervalSince1970: timestamp), value: value)
            }
        }

        return data
    }

    /// Update widget data from a ModelContext and reload all timelines.
    @MainActor
    static func syncAndReload(from context: ModelContext) {
        let descriptor = FetchDescriptor<JournalEntry>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        guard let entries = try? context.fetch(descriptor) else { return }

        let calendar = Calendar.current
        let dates = Set(entries.map { calendar.startOfDay(for: $0.createdAt) })
        let streak = Date().startOfDay.consecutiveDays(in: dates)

        let recentMoods: [(date: Date, value: Double)] = entries.prefix(7).compactMap { entry in
            guard let mood = entry.mood else { return nil }
            return (date: entry.createdAt, value: mood.normalizedValue)
        }

        let moods = entries.compactMap { $0.mood }
        let avgEmoji: String
        if moods.isEmpty {
            avgEmoji = "😐"
        } else {
            let avg = Double(moods.map { $0.rawValue }.reduce(0, +)) / Double(moods.count)
            avgEmoji = Mood(rawValue: Int(avg.rounded()))?.emoji ?? "😐"
        }

        updateWidgetData(streak: streak, totalEntries: entries.count, averageMoodEmoji: avgEmoji, recentMoods: recentMoods)
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Called by the main app to update widget data.
    static func updateWidgetData(streak: Int, totalEntries: Int, averageMoodEmoji: String, recentMoods: [(date: Date, value: Double)]) {
        guard let defaults = UserDefaults(suiteName: appGroupId) else { return }

        defaults.set(streak, forKey: "widget.streak")
        defaults.set(totalEntries, forKey: "widget.totalEntries")
        defaults.set(averageMoodEmoji, forKey: "widget.averageMoodEmoji")

        let encoded: [[String: Double]] = recentMoods.map {
            ["date": $0.date.timeIntervalSince1970, "value": $0.value]
        }
        if let data = try? JSONEncoder().encode(encoded) {
            defaults.set(data, forKey: "widget.recentMoods")
        }
    }
}
