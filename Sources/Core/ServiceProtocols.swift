import Foundation
import SwiftData

// MARK: - Backup Service Protocol

protocol BackupServicing {
    static func createBackup(entries: [JournalEntry], tags: [Tag], password: String) throws -> Data
    static func previewBackup(data: Data, password: String) throws -> BackupService.BackupPreview
    static func restoreBackup(data: Data, password: String, context: ModelContext) throws -> Int
}

extension BackupService: BackupServicing {}

// MARK: - Export Service Protocol

protocol ExportServicing {
    static func exportAll(entries: [JournalEntry], format: ExportService.ExportFormat) -> URL?
}

extension ExportService: ExportServicing {}

// MARK: - App Lock Service Protocol

@MainActor
protocol AppLockServicing: AnyObject {
    var isEnabled: Bool { get set }
    var isLocked: Bool { get set }
    var isAuthenticating: Bool { get }
    var lockOnBackground: Bool { get set }
    var biometricType: AppLockService.BiometricType { get }
    func unlock() async
}

extension AppLockService: AppLockServicing {}
