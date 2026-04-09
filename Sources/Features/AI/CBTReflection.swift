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

        var description: String {
            switch self {
            case .catastrophizing: "Expecting the worst possible outcome"
            case .allOrNothing: "Seeing things in black-or-white with no middle ground"
            case .overgeneralization: "Making broad conclusions from a single event"
            case .mindReading: "Assuming you know what others think"
            case .shouldStatements: "Rigid rules about how things 'should' be"
            case .personalization: "Blaming yourself for things outside your control"
            case .emotionalReasoning: "Believing something is true because it feels true"
            case .labeling: "Attaching a fixed label to yourself or others"
            }
        }

        var reframingSuggestion: String {
            switch self {
            case .catastrophizing: "What's the most likely outcome? What happened last time you feared the worst?"
            case .allOrNothing: "Is there a middle ground? Can both things be partly true?"
            case .overgeneralization: "Is this truly 'always' or 'never'? Can you think of exceptions?"
            case .mindReading: "What evidence do you have? Could there be another explanation?"
            case .shouldStatements: "What if you replaced 'should' with 'I'd prefer'? How does that feel?"
            case .personalization: "What factors were outside your control? Would you blame a friend for this?"
            case .emotionalReasoning: "Just because you feel it doesn't make it true. What are the facts?"
            case .labeling: "One action doesn't define a whole person. What's a more balanced description?"
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
            analysis += "I notice a pattern of **\(primary.type.rawValue)** — \(primary.type.description).\n\n"
            analysis += "Try this reframe: \(primary.reframing)"
        } else {
            analysis += "Your thoughts seem balanced. If something still feels off, try asking: \"What would I tell a friend in this situation?\""
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
