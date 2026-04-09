import Foundation
import LocalAuthentication
import SwiftUI
import OSLog

private let logger = Logger(subsystem: "com.jasonye.kinen", category: "AppLock")

/// App lock using Face ID / Touch ID / password.
/// Protects journal privacy with biometric authentication.
@Observable
@MainActor
final class AppLockService {
    static let shared = AppLockService()

    var isLocked: Bool = false
    var isAuthenticating: Bool = false

    @ObservationIgnored
    @AppStorage("appLockEnabled") var isEnabled: Bool = false
    @ObservationIgnored
    @AppStorage("lockOnBackground") var lockOnBackground: Bool = true

    private init() {
        if isEnabled {
            isLocked = true
        }
    }

    /// Check if biometric authentication is available.
    var biometricType: BiometricType {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }
        switch context.biometryType {
        case .faceID: return .faceID
        case .touchID: return .touchID
        case .opticID: return .opticID
        default: return .none
        }
    }

    enum BiometricType {
        case none, faceID, touchID, opticID

        var name: String {
            switch self {
            case .none: "Passcode"
            case .faceID: "Face ID"
            case .touchID: "Touch ID"
            case .opticID: "Optic ID"
            }
        }

        var icon: String {
            switch self {
            case .none: "lock"
            case .faceID: "faceid"
            case .touchID: "touchid"
            case .opticID: "opticid"
            }
        }
    }

    /// Attempt to unlock using biometrics or device passcode.
    func unlock() async {
        guard isLocked else { return }
        isAuthenticating = true
        defer { isAuthenticating = false }

        let context = LAContext()
        context.localizedCancelTitle = "Cancel"

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication, // Falls back to passcode
                localizedReason: "Unlock your journal"
            )
            if success {
                withAnimation(.easeOut(duration: 0.3)) {
                    isLocked = false
                }
                logger.info("Unlocked successfully")
            }
        } catch {
            logger.error("Authentication failed: \(error)")
        }
    }

    /// Lock the app (called on background/minimize).
    func lock() {
        guard isEnabled && lockOnBackground else { return }
        withAnimation {
            isLocked = true
        }
    }
}
