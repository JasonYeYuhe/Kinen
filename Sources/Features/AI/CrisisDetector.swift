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

    /// Region-aware crisis resources. Shows local resources first, plus the international directory.
    static var crisisResources: [CrisisResource] {
        var resources: [CrisisResource] = []
        let region = Locale.current.region?.identifier ?? ""

        switch region {
        case "US":
            resources.append(CrisisResource(
                name: "988 Suicide & Crisis Lifeline",
                number: "988",
                description: "Call or text 988. Available 24/7.",
                url: URL(string: "https://988lifeline.org")
            ))
            resources.append(CrisisResource(
                name: "Crisis Text Line",
                number: "Text HOME to 741741",
                description: "Free 24/7 text-based crisis support.",
                url: URL(string: "https://www.crisistextline.org")
            ))
        case "CN":
            resources.append(CrisisResource(
                name: "北京心理危机研究与干预中心",
                number: "010-82951332",
                description: "24小时心理援助热线",
                url: nil
            ))
            resources.append(CrisisResource(
                name: "全国心理援助热线",
                number: "400-161-9995",
                description: "24小时免费心理咨询",
                url: nil
            ))
        case "GB":
            resources.append(CrisisResource(
                name: "Samaritans",
                number: "116 123",
                description: "Free 24/7 emotional support.",
                url: URL(string: "https://www.samaritans.org")
            ))
        case "CA":
            resources.append(CrisisResource(
                name: "Talk Suicide Canada",
                number: "988",
                description: "Call or text 988. Available 24/7.",
                url: URL(string: "https://talksuicide.ca")
            ))
        case "AU":
            resources.append(CrisisResource(
                name: "Lifeline Australia",
                number: "13 11 14",
                description: "24/7 crisis support and suicide prevention.",
                url: URL(string: "https://www.lifeline.org.au")
            ))
        case "JP":
            resources.append(CrisisResource(
                name: "いのちの電話",
                number: "0120-783-556",
                description: "無料・24時間対応の相談電話",
                url: URL(string: "https://www.inochinodenwa.org")
            ))
        case "TW":
            resources.append(CrisisResource(
                name: "安心專線",
                number: "1925",
                description: "24小時免費心理諮詢服務",
                url: nil
            ))
        case "KR":
            resources.append(CrisisResource(
                name: "정신건강 위기상담전화",
                number: "1577-0199",
                description: "24시간 정신건강 위기상담",
                url: nil
            ))
        case "DE":
            resources.append(CrisisResource(
                name: "Telefonseelsorge",
                number: "0800 111 0 111",
                description: "Kostenlose 24/7 Krisenberatung.",
                url: URL(string: "https://www.telefonseelsorge.de")
            ))
        case "FR":
            resources.append(CrisisResource(
                name: "SOS Amitié",
                number: "09 72 39 40 50",
                description: "Écoute 24h/24, 7j/7.",
                url: URL(string: "https://www.sos-amitie.com")
            ))
        default:
            break
        }

        // Always include the international directory as a fallback
        resources.append(CrisisResource(
            name: "International Association for Suicide Prevention",
            number: "See website",
            description: "Find crisis centers worldwide.",
            url: URL(string: "https://www.iasp.info/resources/Crisis_Centres/")
        ))

        return resources
    }
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
