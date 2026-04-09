import Foundation
import SwiftUI

/// Detects potential crisis language in journal entries and provides
/// safety resources. This is a critical safety feature.
///
/// IMPORTANT: Kinen is NOT a substitute for professional mental health care.
/// This detector is a best-effort safety net, not a diagnostic tool.
struct CrisisDetector {

    struct CrisisAlert {
        let severity: Severity
        let message: String
        let resources: [CrisisResource]
    }

    enum Severity {
        case low      // general negative language
        case moderate // expressions of hopelessness
        case high     // explicit self-harm language
    }

    struct CrisisResource: Identifiable {
        let id = UUID()
        let name: String
        let number: String
        let description: String
        let url: URL?
    }

    /// Check text for crisis indicators. Returns nil if no concerns detected.
    static func check(_ text: String) -> CrisisAlert? {
        let lowered = text.lowercased()

        // High severity: explicit self-harm or suicidal ideation
        let highRiskPatterns = [
            "want to die", "kill myself", "end my life", "suicide",
            "self harm", "self-harm", "cut myself", "hurt myself",
            "no reason to live", "better off dead", "不想活", "想死",
            "自杀", "自残", "活不下去", "没有活下去的理由"
        ]

        for pattern in highRiskPatterns {
            if lowered.contains(pattern) {
                return CrisisAlert(
                    severity: .high,
                    message: "It sounds like you might be going through something really difficult. You don't have to face this alone.",
                    resources: crisisResources
                )
            }
        }

        // Moderate severity: hopelessness
        let moderatePatterns = [
            "hopeless", "no point", "give up", "can't go on",
            "worthless", "nobody cares", "alone in this",
            "绝望", "没有希望", "放弃了", "没人在乎"
        ]

        let moderateCount = moderatePatterns.filter { lowered.contains($0) }.count
        if moderateCount >= 2 {
            return CrisisAlert(
                severity: .moderate,
                message: "I notice some difficult feelings in your writing. Remember, it's okay to ask for support.",
                resources: crisisResources
            )
        }

        return nil
    }

    static let crisisResources: [CrisisResource] = [
        CrisisResource(
            name: "988 Suicide & Crisis Lifeline",
            number: "988",
            description: "Call or text 988 (US). Available 24/7.",
            url: URL(string: "https://988lifeline.org")
        ),
        CrisisResource(
            name: "Crisis Text Line",
            number: "Text HOME to 741741",
            description: "Free 24/7 text-based crisis support (US).",
            url: URL(string: "https://www.crisistextline.org")
        ),
        CrisisResource(
            name: "Beijing Psychological Crisis Line",
            number: "010-82951332",
            description: "24 hours, Chinese language.",
            url: nil
        ),
        CrisisResource(
            name: "International Association for Suicide Prevention",
            number: "See website",
            description: "Find crisis centers worldwide.",
            url: URL(string: "https://www.iasp.info/resources/Crisis_Centres/")
        ),
    ]
}

/// Crisis alert overlay shown when concerning language is detected.
struct CrisisAlertView: View {
    let alert: CrisisDetector.CrisisAlert
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.text.clipboard")
                .font(.system(size: 40))
                .foregroundStyle(.red)

            Text("You Matter")
                .font(.title2)
                .fontWeight(.bold)

            Text(alert.message)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                Text("Reach out for support:")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                ForEach(alert.resources) { resource in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(resource.name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text(resource.number)
                                .font(.headline)
                                .foregroundStyle(.purple)
                            Text(resource.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if let url = resource.url {
                            Link(destination: url) {
                                Image(systemName: "arrow.up.right.circle")
                                    .font(.title3)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            Divider()

            Text("Kinen is a self-reflection tool, not a substitute for professional mental health care.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)

            Button("I Understand") {
                onDismiss()
            }
            .buttonStyle(.borderedProminent)
            .tint(.purple)
        }
        .padding(24)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(radius: 10)
        .frame(maxWidth: 400)
    }
}
