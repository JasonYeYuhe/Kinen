import Foundation

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
