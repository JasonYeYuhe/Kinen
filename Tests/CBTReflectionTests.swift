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

    func testPersonalization() {
        let result = CBTReflection.analyze("It's my fault everything went wrong. I caused this mess.")
        XCTAssertTrue(result.contains { $0.type == .personalization })
    }

    func testEmotionalReasoning() {
        let result = CBTReflection.analyze("I feel like I'm failing at everything. It feels true so it must be real.")
        XCTAssertTrue(result.contains { $0.type == .emotionalReasoning })
    }

    func testLabeling() {
        let result = CBTReflection.analyze("I'm a loser. I'm worthless and will never amount to anything.")
        XCTAssertTrue(result.contains { $0.type == .labeling })
    }

    // MARK: - CognitiveDistortion enum properties

    func testAllDistortionCasesCount() {
        XCTAssertEqual(CBTReflection.CognitiveDistortion.allCases.count, 8)
    }

    func testRawValues() {
        XCTAssertEqual(CBTReflection.CognitiveDistortion.catastrophizing.rawValue, "Catastrophizing")
        XCTAssertEqual(CBTReflection.CognitiveDistortion.allOrNothing.rawValue, "All-or-Nothing Thinking")
        XCTAssertEqual(CBTReflection.CognitiveDistortion.labeling.rawValue, "Labeling")
    }

    func testTriggerPatternsNonEmpty() {
        for distortion in CBTReflection.CognitiveDistortion.allCases {
            XCTAssertFalse(distortion.triggerPatterns.isEmpty,
                           "\(distortion.rawValue) should have at least one trigger pattern")
        }
    }

    func testLocalizedNamesNonEmpty() {
        for distortion in CBTReflection.CognitiveDistortion.allCases {
            XCTAssertFalse(distortion.localizedName.isEmpty,
                           "\(distortion.rawValue).localizedName should not be empty")
        }
    }

    func testDescriptionsNonEmpty() {
        for distortion in CBTReflection.CognitiveDistortion.allCases {
            XCTAssertFalse(distortion.description.isEmpty,
                           "\(distortion.rawValue).description should not be empty")
        }
    }

    func testReframingSuggestionsNonEmpty() {
        for distortion in CBTReflection.CognitiveDistortion.allCases {
            XCTAssertFalse(distortion.reframingSuggestion.isEmpty,
                           "\(distortion.rawValue).reframingSuggestion should not be empty")
        }
    }

    // MARK: - analyze() logic

    func testConfidenceCapAtOne() {
        // "worst" + "disaster" + "never recover" + "terrible" = 4 catastrophizing matches → min(1.0, 4*0.4) = 1.0
        let results = CBTReflection.analyze(
            "This is the worst disaster ever. I will never recover from this terrible catastrophe.")
        let catastrophizing = results.first { $0.type == .catastrophizing }
        XCTAssertNotNil(catastrophizing)
        XCTAssertEqual(catastrophizing?.confidence ?? 0, 1.0, accuracy: 0.001)
    }

    func testResultsSortedByConfidenceDescending() {
        // shouldStatements: "i should" + "i must" + "i ought to" = 3 matches → confidence 1.0
        // catastrophizing: "worst" = 1 match → confidence 0.4
        let results = CBTReflection.analyze(
            "I should study more, I must be perfect, I ought to do better. It was the worst.")
        guard results.count >= 2 else {
            XCTFail("Expected multiple distortions")
            return
        }
        for i in 0..<results.count - 1 {
            XCTAssertGreaterThanOrEqual(results[i].confidence, results[i + 1].confidence,
                                       "Results should be sorted by confidence descending")
        }
    }

    func testTriggerTextPopulatedWhenSentenceMatches() {
        // "i should have done better" contains trigger "i should" — sentence is long enough (>10 chars)
        let results = CBTReflection.analyze("I should have done better in today's meeting.")
        let shouldMatch = results.first { $0.type == .shouldStatements }
        XCTAssertNotNil(shouldMatch?.triggerText, "triggerText should be set when a matching sentence exists")
    }

    func testGenerateThreeColumnAnalysisReturnsBalancedForHealthyText() {
        let result = CBTReflection.generateThreeColumnAnalysis(
            situation: "Had a pleasant walk in the park",
            automaticThought: "Today was a fine and relaxing day."
        )
        XCTAssertFalse(result.isEmpty, "generateThreeColumnAnalysis should return non-empty string even for healthy text")
    }

    // MARK: - Overgeneralization (no dedicated detection test until now)

    func testOvergeneralization() {
        // "always happens" and "every time" are both overgeneralization triggers
        let result = CBTReflection.analyze("This always happens to me every time I try something new.")
        XCTAssertTrue(result.contains { $0.type == .overgeneralization },
                      "Should detect overgeneralization when 'always happens' / 'every time' patterns are present")
    }

    // MARK: - triggerText nil when no sentence is long enough

    func testTriggerTextNilForShortSentences() {
        // "i never." → overgeneralization trigger matches, but the only sentence
        // is 7 chars which fails the >10 filter → triggerText should be nil
        let results = CBTReflection.analyze("i never.")
        let match = results.first { $0.type == .overgeneralization }
        XCTAssertNotNil(match, "Overgeneralization should still be detected from 'i never'")
        XCTAssertNil(match?.triggerText,
                     "triggerText must be nil when no sentence exceeds 10 characters")
    }
}
