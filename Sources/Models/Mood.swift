import Foundation
import SwiftUI

/// Five-level mood scale with emoji representation.
/// Designed for quick selection and trend visualization.
enum Mood: Int, Codable, CaseIterable, Identifiable {
    case terrible = 1
    case bad = 2
    case neutral = 3
    case good = 4
    case great = 5

    var id: Int { rawValue }

    var emoji: String {
        switch self {
        case .terrible: "😢"
        case .bad: "😔"
        case .neutral: "😐"
        case .good: "😊"
        case .great: "🤩"
        }
    }

    var label: String {
        switch self {
        case .terrible: String(localized: "mood.terrible")
        case .bad: String(localized: "mood.bad")
        case .neutral: String(localized: "mood.neutral")
        case .good: String(localized: "mood.good")
        case .great: String(localized: "mood.great")
        }
    }

    var color: Color {
        switch self {
        case .terrible: .red
        case .bad: .orange
        case .neutral: .gray
        case .good: .green
        case .great: .purple
        }
    }

    /// Numeric value for trend calculation (0.0 to 1.0)
    var normalizedValue: Double {
        Double(rawValue - 1) / 4.0
    }
}
