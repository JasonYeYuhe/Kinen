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

    var body: some View {
        Form {
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

                Button("Export All Entries (\(entries.count))") {
                    exportEntries()
                }
                .disabled(entries.isEmpty)

                if let msg = exportMessage {
                    Text(msg)
                        .font(.caption)
                        .foregroundStyle(.green)
                }
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
}
