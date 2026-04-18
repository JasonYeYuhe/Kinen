import XCTest
@testable import Kinen

final class CrisisDetectorTests: XCTestCase {
    func testHighSeverityEnglish() {
        let result = CrisisDetector.check("I want to kill myself")
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.severity, .high)
        XCTAssertFalse(result?.resources.isEmpty ?? true)
    }

    func testHighSeverityChinese() {
        let result = CrisisDetector.check("我不想活了，想死")
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.severity, .high)
    }

    func testModerateSeverity() {
        let result = CrisisDetector.check("Everything feels hopeless and nobody cares about me.")
        XCTAssertNotNil(result)
        // Should be at least moderate with "hopeless" + "nobody cares"
    }

    func testNormalText() {
        let result = CrisisDetector.check("Had a great day today. Went to the park and played with my dog.")
        XCTAssertNil(result, "Positive text should not trigger crisis detection")
    }

    func testEmptyText() {
        let result = CrisisDetector.check("")
        XCTAssertNil(result)
    }

    func testResourcesAvailable() {
        XCTAssertGreaterThanOrEqual(CrisisDetector.crisisResources.count, 3)
        XCTAssertTrue(CrisisDetector.crisisResources.contains { $0.number == "988" })
    }

    // MARK: - Threshold boundary

    func testSingleModeratePatternDoesNotTrigger() {
        // Only one moderate keyword — threshold requires ≥ 2 to fire
        let result = CrisisDetector.check("I feel hopeless today, but I'll push through it.")
        XCTAssertNil(result, "A single moderate keyword should not reach the moderate-severity threshold")
    }

    func testChineseModeratePatternsTrigger() {
        // "绝望" + "没有希望" are both in the moderate list → count = 2 ≥ 2 → fires
        let result = CrisisDetector.check("我感到绝望，没有希望可言。")
        XCTAssertNotNil(result, "Two Chinese moderate patterns should trigger crisis detection")
        XCTAssertEqual(result?.severity, .moderate)
    }
}
