import SwiftUI

/// Unified haptic feedback manager for iOS.
/// No-op on macOS.
enum HapticManager {
    static func impact(_ style: ImpactStyle = .medium) {
        #if os(iOS)
        let generator: UIImpactFeedbackGenerator
        switch style {
        case .light: generator = UIImpactFeedbackGenerator(style: .light)
        case .medium: generator = UIImpactFeedbackGenerator(style: .medium)
        case .heavy: generator = UIImpactFeedbackGenerator(style: .heavy)
        }
        generator.impactOccurred()
        #endif
    }

    static func notification(_ type: NotificationType) {
        #if os(iOS)
        let generator = UINotificationFeedbackGenerator()
        switch type {
        case .success: generator.notificationOccurred(.success)
        case .warning: generator.notificationOccurred(.warning)
        case .error: generator.notificationOccurred(.error)
        }
        #endif
    }

    static func selection() {
        #if os(iOS)
        UISelectionFeedbackGenerator().selectionChanged()
        #endif
    }

    enum ImpactStyle { case light, medium, heavy }
    enum NotificationType { case success, warning, error }
}
