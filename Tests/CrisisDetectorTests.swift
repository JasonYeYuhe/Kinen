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

    // MARK: - Additional high-severity English patterns

    func testHighSeverityWantToDie() {
        let result = CrisisDetector.check("I want to die and never wake up.")
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.severity, .high)
    }

    func testHighSeverityEndMyLife() {
        let result = CrisisDetector.check("I've been thinking about how to end my life.")
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.severity, .high)
    }

    func testHighSeveritySuicide() {
        let result = CrisisDetector.check("Had thoughts of suicide again tonight.")
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.severity, .high)
    }

    func testHighSeveritySelfHarm() {
        let result = CrisisDetector.check("I've been self-harming to cope with the pain.")
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.severity, .high)
    }

    func testHighSeverityNoReasonToLive() {
        let result = CrisisDetector.check("There is no reason to live anymore.")
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.severity, .high)
    }

    func testHighSeverityBetterOffDead() {
        let result = CrisisDetector.check("Everyone would be better off dead.")
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.severity, .high)
    }

    func testHighSeverityHurtMyself() {
        let result = CrisisDetector.check("I keep wanting to hurt myself.")
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.severity, .high)
    }

    // MARK: - Additional high-severity Chinese patterns

    func testHighSeverityChineseSuicide() {
        let result = CrisisDetector.check("我有自杀的念头。")
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.severity, .high)
    }

    func testHighSeverityChineseCantGoOn() {
        let result = CrisisDetector.check("真的活不下去了。")
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.severity, .high)
    }

    // MARK: - Additional moderate pattern combinations

    func testModerateWorthlessAndAlone() {
        let result = CrisisDetector.check("I feel completely worthless and alone in this.")
        XCTAssertNotNil(result, "worthless + alone in this should trigger moderate")
        XCTAssertEqual(result?.severity, .moderate)
    }

    func testModerateGiveUpAndNoPoint() {
        let result = CrisisDetector.check("I want to give up. There's no point anymore.")
        XCTAssertNotNil(result, "give up + no point should trigger moderate")
        XCTAssertEqual(result?.severity, .moderate)
    }

    func testModerateAlertHasNonEmptyMessage() {
        let result = CrisisDetector.check("I feel worthless and want to give up.")
        XCTAssertNotNil(result)
        XCTAssertFalse(result?.message.isEmpty ?? true, "Moderate alert message should not be empty")
    }

    // MARK: - crisisResources always includes IASP fallback

    func testCrisisResourcesAlwaysIncludesIASP() {
        let resources = CrisisDetector.crisisResources
        XCTAssertTrue(
            resources.contains { $0.name.contains("International") || $0.name.contains("IASP") },
            "IASP international resource should always be included as fallback"
        )
    }

    func testCrisisResourcesAlwaysNonEmpty() {
        XCTAssertGreaterThan(CrisisDetector.crisisResources.count, 0)
    }
}
