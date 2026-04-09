import Foundation

extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    var endOfDay: Date {
        Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: self)!
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }

    var dayOfWeek: Int {
        Calendar.current.component(.weekday, from: self)
    }

    var weekdayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: self)
    }

    var shortDate: String {
        formatted(date: .abbreviated, time: .omitted)
    }

    var relativeDescription: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: self, relativeTo: Date())
    }

    static func daysAgo(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -days, to: Date())!
    }

    /// All dates in a given month
    static func datesInMonth(of date: Date) -> [Date] {
        let calendar = Calendar.current
        let range = calendar.range(of: .day, in: .month, for: date)!
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
        return range.compactMap { day in
            calendar.date(byAdding: .day, value: day - 1, to: startOfMonth)
        }
    }

    /// Consecutive days count ending at this date
    func consecutiveDays(in dates: Set<Date>) -> Int {
        let calendar = Calendar.current
        var count = 0
        var check = self.startOfDay
        while dates.contains(check) {
            count += 1
            check = calendar.date(byAdding: .day, value: -1, to: check)!
        }
        return count
    }
}

extension TimeInterval {
    var formattedDuration: String {
        let minutes = Int(self) / 60
        let seconds = Int(self) % 60
        if minutes >= 60 {
            let hours = minutes / 60
            let mins = minutes % 60
            return "\(hours)h \(mins)m"
        }
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        }
        return "\(seconds)s"
    }
}
