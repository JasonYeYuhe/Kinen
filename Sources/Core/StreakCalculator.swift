import Foundation

/// Centralized streak calculation with freeze-day support.
/// Replaces duplicated streak logic across InsightsScreen, RecapGenerator, and WidgetDataProvider.
struct StreakCalculator {

    struct StreakInfo {
        let current: Int
        let longest: Int
        let hasFreezeToday: Bool  // true if today's streak was saved by a freeze day
    }

    /// Calculate streak info from a set of journaling dates.
    /// - Parameters:
    ///   - dates: All dates that have at least one journal entry
    ///   - freezeDays: Number of allowed missed days without breaking streak (default: 1)
    static func calculate(from dates: Set<Date>, freezeDays: Int = 1) -> StreakInfo {
        let calendar = Calendar.current
        let sortedDates = dates.map { calendar.startOfDay(for: $0) }
        let dateSet = Set(sortedDates)

        guard !dateSet.isEmpty else {
            return StreakInfo(current: 0, longest: 0, hasFreezeToday: false)
        }

        // Calculate current streak (backward from today)
        let today = calendar.startOfDay(for: Date())
        let (current, usedFreeze) = countStreak(from: today, dates: dateSet, calendar: calendar, freezeDays: freezeDays)

        // Calculate longest streak (check from each date)
        var longest = current
        let allDates = dateSet.sorted()
        var i = 0
        while i < allDates.count {
            let (streak, _) = countStreak(from: allDates[i], dates: dateSet, calendar: calendar, freezeDays: freezeDays, forward: true)
            longest = max(longest, streak)
            // Skip ahead to avoid recounting
            i += max(1, streak)
        }

        return StreakInfo(current: current, longest: longest, hasFreezeToday: usedFreeze)
    }

    /// Count consecutive days from a starting date.
    private static func countStreak(
        from start: Date,
        dates: Set<Date>,
        calendar: Calendar,
        freezeDays: Int,
        forward: Bool = false
    ) -> (count: Int, usedFreeze: Bool) {
        let direction = forward ? 1 : -1
        var streak = 0
        var freezesRemaining = freezeDays
        var usedFreeze = false
        var checkDate = start

        // For backward counting, if today has no entry, use one freeze
        if !forward && !dates.contains(checkDate) {
            if freezesRemaining > 0 {
                freezesRemaining -= 1
                usedFreeze = true
            } else {
                return (0, false)
            }
        } else if !forward && dates.contains(checkDate) {
            streak = 1
        } else if forward && dates.contains(checkDate) {
            streak = 1
        } else {
            return (0, false)
        }

        while true {
            guard let nextDate = calendar.date(byAdding: .day, value: direction, to: checkDate) else { break }
            checkDate = nextDate

            if dates.contains(checkDate) {
                streak += 1
                freezesRemaining = freezeDays // reset freeze on active day
            } else if freezesRemaining > 0 {
                freezesRemaining -= 1
                usedFreeze = true
                // Don't increment streak for freeze days, just continue
            } else {
                break
            }
        }

        return (streak, usedFreeze)
    }

    // MARK: - Milestones

    static let milestones = [7, 30, 100, 365]

    /// Check if a streak has newly reached a milestone.
    static func newMilestone(current: Int, achieved: Set<Int>) -> Int? {
        for milestone in milestones {
            if current >= milestone && !achieved.contains(milestone) {
                return milestone
            }
        }
        return nil
    }

    /// Parse achieved milestones from AppStorage string.
    static func parseMilestones(_ string: String) -> Set<Int> {
        Set(string.split(separator: ",").compactMap { Int($0) })
    }

    /// Serialize milestones to AppStorage string.
    static func serializeMilestones(_ set: Set<Int>) -> String {
        set.sorted().map(String.init).joined(separator: ",")
    }
}
