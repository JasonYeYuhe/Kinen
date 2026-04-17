import XCTest
@testable import Kinen

/// Tests for the pure (nonisolated) parts of AIJournalingLoop:
/// life theme detection. The full processEntry pipeline depends on
/// SwiftData ModelContext and is exercised via integration in
/// EntryEditorSheet — not unit tested here.
final class AIJournalingLoopTests: XCTestCase {

    let loop = AIJournalingLoop.shared

    // MARK: - Life Theme Detection

    func testWorkThemeDetected() {
        let themes = loop.detectLifeThemes("Had a tough meeting with my boss about the project deadline.")
        XCTAssertTrue(themes.contains("work"))
    }

    func testRelationshipsThemeDetected() {
        let themes = loop.detectLifeThemes("Spent the evening with my partner and family. Felt close to them.")
        XCTAssertTrue(themes.contains("relationships"))
    }

    func testHealthThemeDetected() {
        let themes = loop.detectLifeThemes("Went to the gym and did a long run. Sleep has been better lately.")
        XCTAssertTrue(themes.contains("health"))
    }

    func testFinanceThemeDetected() {
        let themes = loop.detectLifeThemes("Trying to save more money this month and stick to my budget.")
        XCTAssertTrue(themes.contains("finance"))
    }

    func testGrowthThemeDetected() {
        let themes = loop.detectLifeThemes("Started a new course to learn SwiftUI. Slow progress but improving.")
        XCTAssertTrue(themes.contains("growth"))
    }

    func testCreativityThemeDetected() {
        let themes = loop.detectLifeThemes("Spent the afternoon on my painting and listened to some music while I draw.")
        XCTAssertTrue(themes.contains("creativity"))
    }

    func testTravelThemeDetected() {
        let themes = loop.detectLifeThemes("Booking a flight and a hotel for our vacation in Tokyo.")
        XCTAssertTrue(themes.contains("travel"))
    }

    func testSelfDoubtThemeDetected() {
        let themes = loop.detectLifeThemes("I feel like a failure today. Just not good enough.")
        XCTAssertTrue(themes.contains("self-doubt"))
    }

    func testChineseKeywordsDetected() {
        let themes = loop.detectLifeThemes("今天上班和老板开了个长会。")
        XCTAssertTrue(themes.contains("work"))
    }

    func testNeutralTextHasNoStrongTheme() {
        let themes = loop.detectLifeThemes("The sky was blue.")
        XCTAssertTrue(themes.isEmpty)
    }

    func testThemesRankedByMatchCount() {
        // Multiple work keywords vs one health keyword — work should rank first.
        let text = "Had a meeting at work with my colleague about the project deadline. Also tired."
        let themes = loop.detectLifeThemes(text)
        XCTAssertEqual(themes.first, "work", "Theme with most matching keywords should rank first")
    }

    func testMultipleThemesDetected() {
        let text = "Long meeting at work, then went for a run to clear my head. Trying to save money too."
        let themes = loop.detectLifeThemes(text)
        XCTAssertTrue(themes.contains("work"))
        XCTAssertTrue(themes.contains("health"))
        XCTAssertTrue(themes.contains("finance"))
    }

    func testCaseInsensitiveDetection() {
        let themes = loop.detectLifeThemes("WORK was BRUTAL today")
        XCTAssertTrue(themes.contains("work"))
    }
}
