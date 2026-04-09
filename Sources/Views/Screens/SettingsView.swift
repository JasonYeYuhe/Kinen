import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \JournalEntry.createdAt, order: .reverse) private var entries: [JournalEntry]

    @AppStorage("enableAutoSentiment") private var enableAutoSentiment = true
    @AppStorage("enableAutoTags") private var enableAutoTags = true
    @AppStorage("defaultMoodEnabled") private var defaultMoodEnabled = true
    @State private var appLock = AppLockService.shared
    @State private var showExportPicker = false
    @State private var showTagManagement = false
    @State private var exportFormat: ExportService.ExportFormat = .markdown
    @State private var exportMessage: String?
    @AppStorage("iCloudSyncEnabled") private var iCloudSyncEnabled = true
    @State private var backupPassword = ""
    @State private var backupMessage: String?
    @State private var showBackupPassword = false
    @Query(sort: \Tag.name) private var allTags: [Tag]

    var body: some View {
        Form {
            Section("iCloud Sync") {
                Toggle("Sync entries across devices", isOn: $iCloudSyncEnabled)
                if iCloudSyncEnabled {
                    HStack {
                        Image(systemName: "icloud.fill")
                            .foregroundStyle(.green)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Connected to iCloud")
                                .font(.subheadline)
                            Text("\(entries.count) entries syncing")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    Text("Your entries are stored locally only. Enable sync to access them across your devices.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("AI Analysis") {
                Toggle("Auto-analyze sentiment", isOn: $enableAutoSentiment)
                Toggle("Auto-suggest tags", isOn: $enableAutoTags)
                Text("All AI analysis runs locally on your device. No data is sent anywhere.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Journal") {
                Toggle("Show mood picker for new entries", isOn: $defaultMoodEnabled)
                Button("Manage Tags") { showTagManagement = true }
            }

            Section("Security") {
                Toggle("App Lock (\(appLock.biometricType.name))", isOn: $appLock.isEnabled)
                if appLock.isEnabled {
                    Toggle("Lock when switching apps", isOn: $appLock.lockOnBackground)
                }
            }

            Section("Export") {
                Picker("Format", selection: $exportFormat) {
                    ForEach(ExportService.ExportFormat.allCases, id: \.self) { format in
                        Text(format.rawValue).tag(format)
                    }
                }

                ProButton(title: "Export All Entries (\(entries.count))", icon: "square.and.arrow.up") {
                    exportEntries()
                }

                if let msg = exportMessage {
                    Text(msg)
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }

            Section("Backup & Restore") {
                SecureField("Backup password", text: $backupPassword)
                    .textFieldStyle(.plain)

                ProButton(title: "Create Encrypted Backup", icon: "lock.doc") {
                    createBackup()
                }

                if let msg = backupMessage {
                    Text(msg)
                        .font(.caption)
                        .foregroundStyle(.green)
                }

                Text("Backups are encrypted with AES-256. Keep your password safe — we cannot recover it.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Privacy") {
                HStack {
                    Image(systemName: "lock.shield")
                        .foregroundStyle(.green)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Your Data is Private")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("All journal entries are stored locally on this device. No cloud sync, no tracking, no analytics.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("0.1.0")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Developer")
                    Spacer()
                    Text("Jason Ye")
                        .foregroundStyle(.secondary)
                }
                Link("GitHub", destination: URL(string: "https://github.com/JasonYeYuhe/Kinen")!)
                Link("Privacy Policy", destination: URL(string: "https://jasonyeyuhe.github.io/Kinen/")!)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Settings")
        .sheet(isPresented: $showTagManagement) {
            TagManagementSheet()
        }
    }

    private func exportEntries() {
        #if os(macOS)
        ExportService.exportWithDialog(entries: entries, format: exportFormat)
        exportMessage = "Exported \(entries.count) entries as \(exportFormat.rawValue)"
        #else
        if let url = ExportService.exportAll(entries: entries, format: exportFormat) {
            exportMessage = "Exported to \(url.lastPathComponent)"
        }
        #endif
    }

    private func createBackup() {
        guard !backupPassword.isEmpty else {
            backupMessage = "Please enter a password"
            return
        }
        do {
            let data = try BackupService.createBackup(entries: entries, tags: allTags, password: backupPassword)
            let filename = "kinen-backup-\(Date().formatted(.dateTime.year().month().day())).kinenbackup"
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
            try data.write(to: tempURL)
            #if os(macOS)
            NSWorkspace.shared.open(tempURL.deletingLastPathComponent())
            #endif
            backupMessage = "Backup created: \(filename) (\(data.count / 1024)KB)"
        } catch {
            backupMessage = "Backup failed: \(error.localizedDescription)"
        }
    }
}
