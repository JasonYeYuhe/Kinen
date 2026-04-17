import XCTest
@testable import Kinen

/// Tests for AppLockService.
///
/// Most behavior depends on LAContext (system biometric prompt) which is
/// not mockable from outside. We test what's testable: the BiometricType
/// enum's display properties and the static singleton's initial state.
@MainActor
final class AppLockServiceTests: XCTestCase {

    // MARK: - BiometricType display properties

    func testBiometricTypeNames() {
        XCTAssertEqual(AppLockService.BiometricType.none.name, "Passcode")
        XCTAssertEqual(AppLockService.BiometricType.faceID.name, "Face ID")
        XCTAssertEqual(AppLockService.BiometricType.touchID.name, "Touch ID")
        XCTAssertEqual(AppLockService.BiometricType.opticID.name, "Optic ID")
    }

    func testBiometricTypeIcons() {
        XCTAssertEqual(AppLockService.BiometricType.none.icon, "lock")
        XCTAssertEqual(AppLockService.BiometricType.faceID.icon, "faceid")
        XCTAssertEqual(AppLockService.BiometricType.touchID.icon, "touchid")
        XCTAssertEqual(AppLockService.BiometricType.opticID.icon, "opticid")
    }

    // MARK: - Singleton

    func testSharedInstanceIsStable() {
        let a = AppLockService.shared
        let b = AppLockService.shared
        XCTAssertTrue(a === b)
    }

    // MARK: - biometricType doesn't crash

    func testBiometricTypeQueryDoesNotCrash() {
        // On macOS test runner the underlying LAContext may report any value
        // (none/touchID/etc) — we only assert the call is safe.
        _ = AppLockService.shared.biometricType
    }

    // MARK: - lock() respects flags

    func testLockNoOpsWhenDisabled() {
        let service = AppLockService.shared
        // Snapshot prior state so test runs in any order.
        let priorEnabled = service.isEnabled
        let priorLockOnBg = service.lockOnBackground
        let priorLocked = service.isLocked
        defer {
            service.isEnabled = priorEnabled
            service.lockOnBackground = priorLockOnBg
            service.isLocked = priorLocked
        }

        service.isEnabled = false
        service.isLocked = false
        service.lock()
        XCTAssertFalse(service.isLocked, "lock() should be a no-op when isEnabled=false")
    }

    func testLockNoOpsWhenLockOnBackgroundDisabled() {
        let service = AppLockService.shared
        let priorEnabled = service.isEnabled
        let priorLockOnBg = service.lockOnBackground
        let priorLocked = service.isLocked
        defer {
            service.isEnabled = priorEnabled
            service.lockOnBackground = priorLockOnBg
            service.isLocked = priorLocked
        }

        service.isEnabled = true
        service.lockOnBackground = false
        service.isLocked = false
        service.lock()
        XCTAssertFalse(service.isLocked, "lock() should be a no-op when lockOnBackground=false")
    }

    func testLockSetsIsLockedWhenBothFlagsEnabled() {
        let service = AppLockService.shared
        let priorEnabled = service.isEnabled
        let priorLockOnBg = service.lockOnBackground
        let priorLocked = service.isLocked
        defer {
            service.isEnabled = priorEnabled
            service.lockOnBackground = priorLockOnBg
            service.isLocked = priorLocked
        }

        service.isEnabled = true
        service.lockOnBackground = true
        service.isLocked = false
        service.lock()
        XCTAssertTrue(service.isLocked, "lock() should set isLocked when both flags enabled")
    }
}
