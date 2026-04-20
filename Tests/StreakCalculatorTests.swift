import XCTest
@testable import Kinen

final class StreakCalculatorTests: XCTestCase {

    // MARK: - Helpers

    private let calendar = Calendar.current

    /// Returns a date N days offset from today (startOfDay).
    private func daysAgo(_ n: Int) -> Date {
        let today = calendar.startOfDay(for: Date())
        return calendar.date(byAdding: .day, value: -n, to: today)!
    }

    // MARK: - calculate() — empty / single

    func testEmptyDatesReturnsZero() {
        let result = StreakCalculator.calculate(from: [])
        XCTAssertEqual(result.current, 0)
        XCTAssertEqual(result.longest, 0)
        XCTAssertFalse(result.hasFreezeToday)
    }

    func testSingleDateTodayCurrentIsOne() {
        let result = StreakCalculator.calculate(from: [daysAgo(0)])
        XCTAssertEqual(result.current, 1)
        XCTAssertEqual(result.longest, 1)
    }

    func testSingleDateYesterdayWithFreezeCurrentIsOne() {
        // yesterday + today's freeze → current = 1 (yesterday is the active day)
        let result = StreakCalculator.calculate(from: [daysAgo(1)], freezeDays: 1)
        XCTAssertEqual(result.current, 1)
        XCTAssertTrue(result.hasFreezeToday)
    }

    func testSingleDateYesterdayNoFreezeCurrentIsZero() {
        let result = StreakCalculator.calculate(from: [daysAgo(1)], freezeDays: 0)
        XCTAssertEqual(result.current, 0)
    }

    // MARK: - calculate() — consecutive streaks

    func testThreeConsecutiveDaysCurrentIsThree() {
        // freezeDays=0 so no freeze is used anywhere
        let dates: Set<Date> = [daysAgo(0), daysAgo(1), daysAgo(2)]
        let result = StreakCalculator.calculate(from: dates, freezeDays: 0)
        XCTAssertEqual(result.current, 3)
        XCTAssertEqual(result.longest, 3)
        XCTAssertFalse(result.hasFreezeToday)
    }

    func testGapBreaksStreakWithoutFreeze() {
        // entries 0, 1, 3 ago — day 2 is missing, freeze=0 → current=2 (today + yesterday)
        let dates: Set<Date> = [daysAgo(0), daysAgo(1), daysAgo(3)]
        let result = StreakCalculator.calculate(from: dates, freezeDays: 0)
        XCTAssertEqual(result.current, 2)
        XCTAssertEqual(result.longest, 2)
    }

    func testFreezeAllowsOneGapInCurrentStreak() {
        // entries 0, 1, 3 ago — day 2 is the gap, freeze=1 → current=3
        let dates: Set<Date> = [daysAgo(0), daysAgo(1), daysAgo(3)]
        let result = StreakCalculator.calculate(from: dates, freezeDays: 1)
        XCTAssertEqual(result.current, 3)
    }

    func testLongestStreakExceedsCurrentStreak() {
        // Old 5-day streak far in past, current only 2 days
        var dates: Set<Date> = []
        // 5-day streak ending 20 days ago
        for i in 20...24 { dates.insert(daysAgo(i)) }
        // Current 2-day streak
        dates.insert(daysAgo(0))
        dates.insert(daysAgo(1))

        let result = StreakCalculator.calculate(from: dates, freezeDays: 0)
        XCTAssertEqual(result.current, 2)
        XCTAssertEqual(result.longest, 5)
    }

    func testLongestAndCurrentSameWhenCurrentIsBest() {
        // 7-day active streak through today
        var dates: Set<Date> = []
        for i in 0...6 { dates.insert(daysAgo(i)) }

        let result = StreakCalculator.calculate(from: dates, freezeDays: 0)
        XCTAssertEqual(result.current, 7)
        XCTAssertEqual(result.longest, 7)
    }

    func testNoFreezeWithTodayMissingEndsCurrentStreak() {
        // No entry today, entry yesterday and before — freeze=0 → current=0
        let dates: Set<Date> = [daysAgo(1), daysAgo(2), daysAgo(3)]
        let result = StreakCalculator.calculate(from: dates, freezeDays: 0)
        XCTAssertEqual(result.current, 0)
        XCTAssertEqual(result.longest, 3)
    }

    func testFreezeResetOnActiveDay() {
        // Streak: today, skip, yesterday-2, yesterday-3, skip, yesterday-5
        // With freeze=1 each skip gets bridged if only one gap in a row
        let dates: Set<Date> = [daysAgo(0), daysAgo(2), daysAgo(3), daysAgo(5)]
        let result = StreakCalculator.calculate(from: dates, freezeDays: 1)
        // Backwards: today(1) + freeze(skip 1) + day2(2) + day3(3) + freeze(skip 4) + day5(4)
        XCTAssertEqual(result.current, 4)
    }

    // MARK: - newMilestone()

    func testNewMilestoneAtSeven() {
        let milestone = StreakCalculator.newMilestone(current: 7, achieved: [])
        XCTAssertEqual(milestone, 7)
    }

    func testNoMilestoneWhenAlreadyAchieved() {
        let milestone = StreakCalculator.newMilestone(current: 7, achieved: [7])
        XCTAssertNil(milestone)
    }

    func testMilestoneReturnsLowestUnachieved() {
        // current=100, achieved=[7,30] → should return 100
        let milestone = StreakCalculator.newMilestone(current: 100, achieved: [7, 30])
        XCTAssertEqual(milestone, 100)
    }

    func testNoMilestoneWhenStreakBelowThreshold() {
        let milestone = StreakCalculator.newMilestone(current: 5, achieved: [])
        XCTAssertNil(milestone)
    }

    func testAllMilestonesAchievedReturnsNil() {
        let milestone = StreakCalculator.newMilestone(current: 365, achieved: [7, 30, 100, 365])
        XCTAssertNil(milestone)
    }

    func testMilestoneAt30() {
        let milestone = StreakCalculator.newMilestone(current: 30, achieved: [7])
        XCTAssertEqual(milestone, 30)
    }

    // MARK: - parseMilestones() / serializeMilestones()

    func testParseEmptyStringReturnsEmptySet() {
        let result = StreakCalculator.parseMilestones("")
        XCTAssertTrue(result.isEmpty)
    }

    func testParseSingleMilestone() {
        let result = StreakCalculator.parseMilestones("7")
        XCTAssertEqual(result, [7])
    }

    func testParseMultipleMilestones() {
        let result = StreakCalculator.parseMilestones("7,30,100")
        XCTAssertEqual(result, [7, 30, 100])
    }

    func testSerializeEmptySetReturnsEmptyString() {
        let result = StreakCalculator.serializeMilestones([])
        XCTAssertEqual(result, "")
    }

    func testSerializeSingleMilestone() {
        let result = StreakCalculator.serializeMilestones([7])
        XCTAssertEqual(result, "7")
    }

    func testSerializeIsSorted() {
        let result = StreakCalculator.serializeMilestones([100, 7, 30])
        XCTAssertEqual(result, "7,30,100")
    }

    func testRoundTripMilestones() {
        let original: Set<Int> = [7, 30, 100]
        let serialized = StreakCalculator.serializeMilestones(original)
        let parsed = StreakCalculator.parseMilestones(serialized)
        XCTAssertEqual(parsed, original)
    }

    func testParseMilestonesDeduplicates() {
        // Duplicate values in string collapse into a single-element Set
        let result = StreakCalculator.parseMilestones("7,7,7")
        XCTAssertEqual(result, [7])
    }

    func testNewMilestoneAt365WhenLowerMilestonesAchieved() {
        // current=365, [7,30,100] already achieved → first unachieved milestone ≥ current is 365
        let milestone = StreakCalculator.newMilestone(current: 365, achieved: [7, 30, 100])
        XCTAssertEqual(milestone, 365)
    }
}
