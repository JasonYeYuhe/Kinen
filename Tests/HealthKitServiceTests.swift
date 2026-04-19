import XCTest
@testable import Kinen

/// Tests for the testable parts of HealthKitService:
/// - mergedDuration interval merging (pure function)
/// - generateCorrelationInsight (with manually-set state)
///
/// HKHealthStore queries themselves require a real device + permissions
/// and are exercised manually.
@MainActor
final class HealthKitServiceTests: XCTestCase {

    // MARK: - mergedDuration

    func testMergedDurationOnEmptyIntervalsIsZero() {
        XCTAssertEqual(HealthKitService.mergedDuration(intervals: []), 0)
    }

    func testMergedDurationSingleIntervalIsItsLength() {
        let start = Date(timeIntervalSince1970: 1_000_000)
        let end = start.addingTimeInterval(3600)
        let total = HealthKitService.mergedDuration(intervals: [(start, end)])
        XCTAssertEqual(total, 3600, accuracy: 0.01)
    }

    func testMergedDurationNonOverlappingIntervalsSum() {
        let base = Date(timeIntervalSince1970: 1_000_000)
        let intervals = [
            (start: base, end: base.addingTimeInterval(3600)),                     // 1h
            (start: base.addingTimeInterval(7200), end: base.addingTimeInterval(9000)) // 0.5h
        ]
        let total = HealthKitService.mergedDuration(intervals: intervals)
        XCTAssertEqual(total, 5400, accuracy: 0.01)
    }

    func testMergedDurationOverlappingIntervalsCountedOnce() {
        // Two samples for the same hour should not be double-counted (the bug
        // this function exists to fix — Apple Watch + iPhone often log overlapping
        // sleep samples).
        let base = Date(timeIntervalSince1970: 1_000_000)
        let intervals = [
            (start: base, end: base.addingTimeInterval(3600)),
            (start: base.addingTimeInterval(1800), end: base.addingTimeInterval(5400))
        ]
        let total = HealthKitService.mergedDuration(intervals: intervals)
        XCTAssertEqual(total, 5400, accuracy: 0.01, "Overlapping intervals should merge, not sum")
    }

    func testMergedDurationContainedIntervalIsAbsorbed() {
        let base = Date(timeIntervalSince1970: 1_000_000)
        let intervals = [
            (start: base, end: base.addingTimeInterval(7200)),                       // big: 2h
            (start: base.addingTimeInterval(1800), end: base.addingTimeInterval(3600)) // inside
        ]
        let total = HealthKitService.mergedDuration(intervals: intervals)
        XCTAssertEqual(total, 7200, accuracy: 0.01, "Contained interval should not extend total")
    }

    func testMergedDurationOutOfOrderInputProducesSameResult() {
        let base = Date(timeIntervalSince1970: 1_000_000)
        let inOrder = [
            (start: base, end: base.addingTimeInterval(3600)),
            (start: base.addingTimeInterval(7200), end: base.addingTimeInterval(9000))
        ]
        let reversed: [(start: Date, end: Date)] = inOrder.reversed()
        XCTAssertEqual(
            HealthKitService.mergedDuration(intervals: inOrder),
            HealthKitService.mergedDuration(intervals: reversed),
            accuracy: 0.01
        )
    }

    func testMergedDurationAdjacentIntervalsMergeCleanly() {
        // Two samples that touch at the boundary should merge.
        let base = Date(timeIntervalSince1970: 1_000_000)
        let intervals = [
            (start: base, end: base.addingTimeInterval(3600)),
            (start: base.addingTimeInterval(3600), end: base.addingTimeInterval(7200))
        ]
        let total = HealthKitService.mergedDuration(intervals: intervals)
        XCTAssertEqual(total, 7200, accuracy: 0.01)
    }

    // MARK: - generateCorrelationInsight

    func testCorrelationInsightLowSleepWithBadMood() {
        let service = HealthKitService.shared
        service.todaySleep = 5.0
        service.todaySteps = nil
        service.todayRestingHR = nil

        let entry = JournalEntry(content: "Rough day", mood: .bad)
        let insight = service.generateCorrelationInsight(entries: [entry])
        XCTAssertNotNil(insight)
    }

    func testCorrelationInsightGoodSleepWithGoodMood() {
        let service = HealthKitService.shared
        service.todaySleep = 8.0
        service.todaySteps = nil
        service.todayRestingHR = nil

        let entry = JournalEntry(content: "Felt great", mood: .great)
        let insight = service.generateCorrelationInsight(entries: [entry])
        XCTAssertNotNil(insight)
    }

    func testCorrelationInsightActiveDayWithGoodMood() {
        let service = HealthKitService.shared
        service.todaySleep = 7.0  // neutral, won't trigger sleep insights
        service.todaySteps = 10_000
        service.todayRestingHR = nil

        let entry = JournalEntry(content: "Productive", mood: .good)
        let insight = service.generateCorrelationInsight(entries: [entry])
        XCTAssertNotNil(insight)
    }

    func testCorrelationInsightReturnsNilWithoutSleepData() {
        let service = HealthKitService.shared
        service.todaySleep = nil
        service.todaySteps = nil
        service.todayRestingHR = nil

        let entry = JournalEntry(content: "Whatever", mood: .neutral)
        XCTAssertNil(service.generateCorrelationInsight(entries: [entry]))
    }

    func testCorrelationInsightReturnsNilWithoutEntries() {
        let service = HealthKitService.shared
        service.todaySleep = 5.0
        XCTAssertNil(service.generateCorrelationInsight(entries: []))
    }

    func testCorrelationInsightReturnsNilWhenNoMatchingPattern() {
        // Good sleep + bad mood — none of the heuristics fire.
        let service = HealthKitService.shared
        service.todaySleep = 8.0
        service.todaySteps = 1000
        service.todayRestingHR = nil

        let entry = JournalEntry(content: "Tough day", mood: .bad)
        XCTAssertNil(service.generateCorrelationInsight(entries: [entry]))
    }

    // MARK: - Boundary Values

    func testCorrelationInsightSleepExactly6WithBadMoodIsNil() {
        // sleep < 6 is the condition — exactly 6.0 must NOT trigger lowSleep insight
        let service = HealthKitService.shared
        service.todaySleep = 6.0
        service.todaySteps = nil
        service.todayRestingHR = nil
        let entry = JournalEntry(content: "Bad day", mood: .bad)
        XCTAssertNil(service.generateCorrelationInsight(entries: [entry]),
                     "sleep == 6.0 should not trigger lowSleep insight (condition is < 6, not <= 6)")
    }

    func testCorrelationInsightSleepExactly75WithGoodMoodIsNil() {
        // sleep > 7.5 is the condition — exactly 7.5 must NOT trigger goodSleep insight
        let service = HealthKitService.shared
        service.todaySleep = 7.5
        service.todaySteps = nil
        service.todayRestingHR = nil
        let entry = JournalEntry(content: "Good day", mood: .good)
        XCTAssertNil(service.generateCorrelationInsight(entries: [entry]),
                     "sleep == 7.5 should not trigger goodSleep insight (condition is > 7.5, not >= 7.5)")
    }

    func testCorrelationInsightStepsExactly8000WithGoodMoodIsNil() {
        // steps > 8000 is the condition — exactly 8000 must NOT trigger activeDay insight.
        // todaySleep must be non-nil (neutral 7.0) to pass the guard.
        let service = HealthKitService.shared
        service.todaySleep = 7.0
        service.todaySteps = 8000
        service.todayRestingHR = nil
        let entry = JournalEntry(content: "Good day", mood: .good)
        XCTAssertNil(service.generateCorrelationInsight(entries: [entry]),
                     "steps == 8000 should not trigger activeDay insight (condition is > 8000, not >= 8000)")
    }

    func testCorrelationInsightHighStepsWithTerribleMoodIsNil() {
        // steps > 8000 but mood is .terrible — activeDay condition requires .good/.great
        let service = HealthKitService.shared
        service.todaySleep = 7.0
        service.todaySteps = 12_000
        service.todayRestingHR = nil
        let entry = JournalEntry(content: "Terrible day despite walking", mood: .terrible)
        XCTAssertNil(service.generateCorrelationInsight(entries: [entry]),
                     "high step count with terrible mood should not trigger activeDay insight")
    }

    func testCorrelationInsightLowSleepWithGreatMoodIsNil() {
        // sleep < 6 but mood is .great — lowSleep condition requires .bad/.terrible
        let service = HealthKitService.shared
        service.todaySleep = 4.0
        service.todaySteps = nil
        service.todayRestingHR = nil
        let entry = JournalEntry(content: "Great day despite little sleep", mood: .great)
        XCTAssertNil(service.generateCorrelationInsight(entries: [entry]),
                     "low sleep with great mood should not trigger lowSleep insight (mood guard mismatch)")
    }

    func testCorrelationInsightNilSleepWithHighStepsIsNil() {
        // todaySleep nil → guard returns nil immediately; steps are never evaluated
        let service = HealthKitService.shared
        service.todaySleep = nil
        service.todaySteps = 15_000
        service.todayRestingHR = nil
        let entry = JournalEntry(content: "Walked all day", mood: .great)
        XCTAssertNil(service.generateCorrelationInsight(entries: [entry]),
                     "nil sleep guard forces nil regardless of step count")
    }
}
