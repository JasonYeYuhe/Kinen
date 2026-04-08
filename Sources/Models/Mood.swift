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
        case .terrible: String(localized: "Terrible")
        case .bad: String(localized: "Bad")
        case .neutral: String(localized: "Neutral")
        case .good: String(localized: "Good")
        case .great: String(localized: "Great")
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
