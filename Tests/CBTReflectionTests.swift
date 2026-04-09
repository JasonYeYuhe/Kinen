import XCTest
@testable import Kinen

final class CBTReflectionTests: XCTestCase {
    func testCatastrophizing() {
        let result = CBTReflection.analyze("This is the worst disaster ever. Everything is ruined and I'll never recover.")
        XCTAssertFalse(result.isEmpty)
        XCTAssertTrue(result.contains { $0.type == .catastrophizing })
    }

    func testAllOrNothing() {
        let result = CBTReflection.analyze("Nothing ever works out. Everyone always lets me down. I totally failed.")
        XCTAssertTrue(result.contains { $0.type == .allOrNothing || $0.type == .overgeneralization })
    }

    func testShouldStatements() {
        let result = CBTReflection.analyze("I should have done better. I must work harder. I ought to be perfect.")
        XCTAssertTrue(result.contains { $0.type == .shouldStatements })
    }

    func testMindReading() {
        let result = CBTReflection.analyze("They think I'm stupid. She probably thinks I'm worthless.")
        XCTAssertTrue(result.contains { $0.type == .mindReading })
    }

    func testNoDistortions() {
        let result = CBTReflection.analyze("Today was a normal day. I went for a walk and had lunch with a friend.")
        XCTAssertTrue(result.isEmpty, "Healthy text should not trigger distortions")
    }

    func testThreeColumnAnalysis() {
        let analysis = CBTReflection.generateThreeColumnAnalysis(
            situation: "Failed a presentation at work",
            automaticThought: "I'm a total failure. Everyone thinks I'm stupid."
        )
        XCTAssertFalse(analysis.isEmpty)
    }
}
