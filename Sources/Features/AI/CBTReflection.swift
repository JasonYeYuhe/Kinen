import Foundation
import NaturalLanguage

/// On-device CBT (Cognitive Behavioral Therapy) reflection engine.
/// Identifies cognitive distortions in journal text and suggests reframing.
/// All processing uses Apple NaturalLanguage framework — no cloud, no downloads.
struct CBTReflection {

    /// Known cognitive distortion patterns
    enum CognitiveDistortion: String, CaseIterable {
        case catastrophizing = "Catastrophizing"
        case allOrNothing = "All-or-Nothing Thinking"
        case overgeneralization = "Overgeneralization"
        case mindReading = "Mind Reading"
        case shouldStatements = "Should Statements"
        case personalization = "Personalization"
        case emotionalReasoning = "Emotional Reasoning"
        case labeling = "Labeling"

        var localizedName: String {
            switch self {
            case .catastrophizing: String(localized: "cbt.distortion.catastrophizing.name")
            case .allOrNothing: String(localized: "cbt.distortion.allOrNothing.name")
            case .overgeneralization: String(localized: "cbt.distortion.overgeneralization.name")
            case .mindReading: String(localized: "cbt.distortion.mindReading.name")
            case .shouldStatements: String(localized: "cbt.distortion.shouldStatements.name")
            case .personalization: String(localized: "cbt.distortion.personalization.name")
            case .emotionalReasoning: String(localized: "cbt.distortion.emotionalReasoning.name")
            case .labeling: String(localized: "cbt.distortion.labeling.name")
            }
        }

        var description: String {
            switch self {
            case .catastrophizing: String(localized: "cbt.distortion.catastrophizing.description")
            case .allOrNothing: String(localized: "cbt.distortion.allOrNothing.description")
            case .overgeneralization: String(localized: "cbt.distortion.overgeneralization.description")
            case .mindReading: String(localized: "cbt.distortion.mindReading.description")
            case .shouldStatements: String(localized: "cbt.distortion.shouldStatements.description")
            case .personalization: String(localized: "cbt.distortion.personalization.description")
            case .emotionalReasoning: String(localized: "cbt.distortion.emotionalReasoning.description")
            case .labeling: String(localized: "cbt.distortion.labeling.description")
            }
        }

        var reframingSuggestion: String {
            switch self {
            case .catastrophizing: String(localized: "cbt.distortion.catastrophizing.reframe")
            case .allOrNothing: String(localized: "cbt.distortion.allOrNothing.reframe")
            case .overgeneralization: String(localized: "cbt.distortion.overgeneralization.reframe")
            case .mindReading: String(localized: "cbt.distortion.mindReading.reframe")
            case .shouldStatements: String(localized: "cbt.distortion.shouldStatements.reframe")
            case .personalization: String(localized: "cbt.distortion.personalization.reframe")
            case .emotionalReasoning: String(localized: "cbt.distortion.emotionalReasoning.reframe")
            case .labeling: String(localized: "cbt.distortion.labeling.reframe")
            }
        }

        /// Keyword patterns that suggest this distortion
        var triggerPatterns: [String] {
            switch self {
            case .catastrophizing:
                return ["worst", "disaster", "terrible", "ruined", "never recover", "end of the world", "catastrophe", "hopeless"]
            case .allOrNothing:
                return ["always", "never", "everyone", "no one", "completely", "totally", "nothing ever", "everything is"]
            case .overgeneralization:
                return ["always happens", "this always", "i never", "every time", "nothing good", "everything bad"]
            case .mindReading:
                return ["they think", "he thinks", "she thinks", "they must", "probably thinks", "they don't care", "nobody cares"]
            case .shouldStatements:
                return ["i should", "i must", "i have to", "i need to", "i ought to", "they should", "shouldn't have"]
            case .personalization:
                return ["my fault", "i caused", "because of me", "i'm to blame", "i ruined", "if only i"]
            case .emotionalReasoning:
                return ["i feel like", "i feel that", "it feels like", "feels true", "i just know", "my gut says"]
            case .labeling:
                return ["i'm a failure", "i'm stupid", "i'm worthless", "i'm a loser", "he's a", "she's a", "they're all"]
            }
        }
    }

    /// Analyze text for cognitive distortions.
    /// Returns detected distortions with confidence and reframing suggestions.
    static func analyze(_ text: String) -> [DetectedDistortion] {
        let lowered = text.lowercased()
        var results: [DetectedDistortion] = []

        for distortion in CognitiveDistortion.allCases {
            let matchCount = distortion.triggerPatterns.filter { lowered.contains($0) }.count
            if matchCount > 0 {
                // Find the matching sentence for context
                let sentences = text.components(separatedBy: CharacterSet(charactersIn: ".!?\n"))
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { $0.count > 10 }

                let matchingSentence = sentences.first { sentence in
                    distortion.triggerPatterns.contains { sentence.lowercased().contains($0) }
                }

                results.append(DetectedDistortion(
                    type: distortion,
                    confidence: min(1.0, Double(matchCount) * 0.4),
                    triggerText: matchingSentence,
                    reframing: distortion.reframingSuggestion
                ))
            }
        }

        return results.sorted { $0.confidence > $1.confidence }
    }

    /// Generate a CBT three-column analysis from text.
    static func generateThreeColumnAnalysis(situation: String, automaticThought: String) -> String {
        let distortions = analyze(automaticThought)
        var analysis = ""

        if !distortions.isEmpty {
            let primary = distortions[0]
            analysis += String(format: String(localized: "cbt.analysis.pattern"), primary.type.localizedName, primary.type.description)
            analysis += "\n\n"
            analysis += String(format: String(localized: "cbt.analysis.reframe"), primary.reframing)
        } else {
            analysis += String(localized: "cbt.analysis.balanced")
        }

        return analysis
    }
}

struct DetectedDistortion: Identifiable {
    let id = UUID()
    let type: CBTReflection.CognitiveDistortion
    let confidence: Double
    let triggerText: String?
    let reframing: String
}
