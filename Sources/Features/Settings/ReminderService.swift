import Foundation
import UserNotifications
import OSLog

@Observable @MainActor
final class ReminderService {
    static let shared = ReminderService()

    var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "reminderEnabled") }
        set {
            UserDefaults.standard.set(newValue, forKey: "reminderEnabled")
            if newValue {
                scheduleReminder()
            } else {
                cancelReminder()
            }
        }
    }

    var reminderHour: Int {
        get { UserDefaults.standard.object(forKey: "reminderHour") as? Int ?? 21 }
        set {
            UserDefaults.standard.set(newValue, forKey: "reminderHour")
            if isEnabled { scheduleReminder() }
        }
    }

    var reminderMinute: Int {
        get { UserDefaults.standard.object(forKey: "reminderMinute") as? Int ?? 0 }
        set {
            UserDefaults.standard.set(newValue, forKey: "reminderMinute")
            if isEnabled { scheduleReminder() }
        }
    }

    var reminderTime: Date {
        get {
            var components = DateComponents()
            components.hour = reminderHour
            components.minute = reminderMinute
            return Calendar.current.date(from: components) ?? Date()
        }
        set {
            let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
            reminderHour = components.hour ?? 21
            reminderMinute = components.minute ?? 0
        }
    }

    private let logger = Logger(subsystem: "com.jasonye.kinen", category: "Reminder")
    private let notificationId = "com.jasonye.kinen.dailyReminder"

    private let prompts: [String] = [
        String(localized: "reminder.prompt1"),
        String(localized: "reminder.prompt2"),
        String(localized: "reminder.prompt3"),
        String(localized: "reminder.prompt4"),
        String(localized: "reminder.prompt5"),
    ]

    func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            logger.info("Notification permission: \(granted)")
            return granted
        } catch {
            logger.error("Failed to request notification permission: \(error)")
            return false
        }
    }

    func scheduleReminder() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [notificationId])

        let content = UNMutableNotificationContent()
        content.title = String(localized: "reminder.title")
        content.body = prompts.randomElement() ?? prompts[0]
        content.sound = .default
        content.categoryIdentifier = "JOURNAL_REMINDER"

        var dateComponents = DateComponents()
        dateComponents.hour = reminderHour
        dateComponents.minute = reminderMinute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: notificationId, content: content, trigger: trigger)

        let hour = reminderHour
        let minute = reminderMinute
        center.add(request) { [logger] error in
            if let error {
                logger.error("Failed to schedule reminder: \(error)")
            } else {
                logger.info("Daily reminder scheduled at \(hour):\(minute)")
            }
        }
    }

    func cancelReminder() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [notificationId])
        logger.info("Daily reminder cancelled")
    }

    /// Schedule a one-time milestone notification
    func scheduleMilestone(days: Int) {
        let center = UNUserNotificationCenter.current()
        let id = "com.jasonye.kinen.milestone.\(days)"
        center.removePendingNotificationRequests(withIdentifiers: [id])

        let content = UNMutableNotificationContent()
        content.title = String(localized: "reminder.milestone.title")
        content.body = String(localized: "reminder.milestone.body.\(days)")
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        center.add(request)
    }

    /// Schedule an On This Day notification if entries exist from exactly 1 year ago.
    func scheduleOnThisDayIfNeeded(entries: [Any], preview: String) {
        guard UserDefaults.standard.bool(forKey: "onThisDayEnabled") else { return }
        let center = UNUserNotificationCenter.current()
        let id = "com.jasonye.kinen.onthisday"
        center.removePendingNotificationRequests(withIdentifiers: [id])

        guard !preview.isEmpty else { return }

        let content = UNMutableNotificationContent()
        content.title = String(localized: "onThisDay.notification.title")
        content.body = String(format: String(localized: "onThisDay.notification.body"), String(preview.prefix(100)))
        content.sound = .default

        // Schedule for 9 AM tomorrow
        var dateComponents = DateComponents()
        dateComponents.hour = 9
        dateComponents.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        center.add(request) { [logger] error in
            if let error { logger.error("On This Day notification failed: \(error)") }
            else { logger.info("On This Day notification scheduled") }
        }
    }

    private init() {}
}
