import XCTest
@testable import Kinen

/// Tests for the UserDefaults-backed properties and reminderTime computed property
/// of ReminderService. Notification scheduling is NOT tested (requires device + permission).
@MainActor
final class ReminderServiceTests: XCTestCase {

    private let defaults = UserDefaults.standard

    override func tearDown() {
        super.tearDown()
        defaults.removeObject(forKey: "reminderHour")
        defaults.removeObject(forKey: "reminderMinute")
        defaults.removeObject(forKey: "reminderEnabled")
    }

    // MARK: - Default values

    func testReminderHourDefaultIs21() {
        defaults.removeObject(forKey: "reminderHour")
        XCTAssertEqual(ReminderService.shared.reminderHour, 21,
                       "reminderHour should default to 21 when key not set")
    }

    func testReminderMinuteDefaultIsZero() {
        defaults.removeObject(forKey: "reminderMinute")
        XCTAssertEqual(ReminderService.shared.reminderMinute, 0,
                       "reminderMinute should default to 0 when key not set")
    }

    func testIsEnabledDefaultIsFalse() {
        defaults.removeObject(forKey: "reminderEnabled")
        XCTAssertFalse(ReminderService.shared.isEnabled,
                       "isEnabled should default to false when key not set")
    }

    // MARK: - Getters reflect stored values

    func testReminderHourGetterReturnsStoredValue() {
        defaults.set(8, forKey: "reminderHour")
        XCTAssertEqual(ReminderService.shared.reminderHour, 8)
    }

    func testReminderMinuteGetterReturnsStoredValue() {
        defaults.set(45, forKey: "reminderMinute")
        XCTAssertEqual(ReminderService.shared.reminderMinute, 45)
    }

    // MARK: - reminderTime computed property

    func testReminderTimeDefaultIs21h00() {
        defaults.removeObject(forKey: "reminderHour")
        defaults.removeObject(forKey: "reminderMinute")
        let time = ReminderService.shared.reminderTime
        let comps = Calendar.current.dateComponents([.hour, .minute], from: time)
        XCTAssertEqual(comps.hour, 21, "Default reminderTime hour should be 21")
        XCTAssertEqual(comps.minute, 0, "Default reminderTime minute should be 0")
    }

    func testReminderTimeSetterExtractsHourAndMinute() {
        // Set isEnabled=false to prevent scheduleReminder() side effects
        defaults.set(false, forKey: "reminderEnabled")
        var comps = DateComponents()
        comps.hour = 9
        comps.minute = 30
        let nineThirty = Calendar.current.date(from: comps)!
        ReminderService.shared.reminderTime = nineThirty
        XCTAssertEqual(ReminderService.shared.reminderHour, 9,
                       "reminderTime setter should store extracted hour")
        XCTAssertEqual(ReminderService.shared.reminderMinute, 30,
                       "reminderTime setter should store extracted minute")
    }

    // MARK: - Setters write through to UserDefaults

    func testReminderHourSetterStoresInUserDefaults() {
        defaults.set(false, forKey: "reminderEnabled")
        ReminderService.shared.reminderHour = 14
        XCTAssertEqual(defaults.object(forKey: "reminderHour") as? Int, 14,
                       "reminderHour setter should persist value to UserDefaults")
    }

    func testReminderMinuteSetterStoresInUserDefaults() {
        defaults.set(false, forKey: "reminderEnabled")
        ReminderService.shared.reminderMinute = 45
        XCTAssertEqual(defaults.object(forKey: "reminderMinute") as? Int, 45,
                       "reminderMinute setter should persist value to UserDefaults")
    }

    func testIsEnabledSetterFalseStoresInUserDefaults() {
        defaults.set(true, forKey: "reminderEnabled")
        ReminderService.shared.isEnabled = false
        XCTAssertFalse(defaults.bool(forKey: "reminderEnabled"),
                       "isEnabled setter should persist false to UserDefaults")
    }

    // MARK: - scheduleOnThisDayIfNeeded guard exits

    func testScheduleOnThisDayDisabledExitsEarly() {
        // Guard 1: onThisDayEnabled=false → method returns before touching UNUserNotificationCenter
        defaults.set(false, forKey: "onThisDayEnabled")
        defer { defaults.removeObject(forKey: "onThisDayEnabled") }
        // Should not crash and should not schedule anything
        ReminderService.shared.scheduleOnThisDayIfNeeded(entries: [], preview: "some preview")
    }

    func testScheduleOnThisDayEmptyPreviewExitsEarly() {
        // Guard 2: preview.isEmpty → removes pending notification then returns without scheduling
        defaults.set(true, forKey: "onThisDayEnabled")
        defer { defaults.removeObject(forKey: "onThisDayEnabled") }
        // Should not crash; removePendingNotificationRequests is a no-op when none pending
        ReminderService.shared.scheduleOnThisDayIfNeeded(entries: [], preview: "")
    }
}
