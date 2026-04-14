import SwiftUI
import SwiftData
import StoreKit
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.requestReview) private var requestReviewAction
    @Query(sort: \JournalEntry.createdAt, order: .reverse) private var entries: [JournalEntry]

    @AppStorage("enableAutoSentiment") private var enableAutoSentiment = true
    @AppStorage("enableAutoTags") private var enableAutoTags = true
    @AppStorage("defaultMoodEnabled") private var defaultMoodEnabled = true
    @AppStorage("enableLocationWeather") private var enableLocationWeather = false
    @AppStorage("enableHealthKit") private var enableHealthKit = false
    @State private var healthKit = HealthKitService.shared
    @State private var appLock = AppLockService.shared
    @State private var reminder = ReminderService.shared
    @State private var showExportPicker = false
    @State private var showTagManagement = false
    @State private var showJournalManagement = false
    @State private var exportFormat: ExportService.ExportFormat = .markdown
    @State private var exportMessage: String?
    @AppStorage("iCloudSyncEnabled") private var iCloudSyncEnabled = false
    @State private var backupPassword = ""
    @State private var backupMessage: String?
    @State private var showBackupPassword = false
    @State private var showRestoreFilePicker = false
    @State private var restorePassword = ""
    @State private var restoreMessage: String?
    @State private var restoreIsError = false
    @State private var pendingRestoreURL: URL?
    @State private var pendingRestoreData: Data?
    @State private var restorePreview: BackupService.BackupPreview?
    @State private var showRestorePasswordPrompt = false
    @State private var showRestoreConfirmation = false
    @Query(sort: \Tag.name) private var allTags: [Tag]

    var body: some View {
        Form {
            Section(String(localized: "settings.icloud")) {
                Toggle(String(localized: "settings.icloud.toggle"), isOn: $iCloudSyncEnabled)
                if iCloudSyncEnabled {
                    HStack {
                        Image(systemName: "icloud.fill")
                            .foregroundStyle(.green)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(String(localized: "settings.icloud.connected"))
                                .font(.subheadline)
                            Text("\(entries.count) \(String(localized: "general.entries"))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    Text(String(localized: "settings.icloud.disabled"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text(String(localized: "settings.icloud.note"))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Section(String(localized: "settings.ai")) {
                Toggle(String(localized: "settings.ai.sentiment"), isOn: $enableAutoSentiment)
                Toggle(String(localized: "settings.ai.tags"), isOn: $enableAutoTags)
                Text(String(localized: "settings.ai.local"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section(String(localized: "settings.journal")) {
                Toggle(String(localized: "settings.journal.mood"), isOn: $defaultMoodEnabled)
                Toggle(String(localized: "settings.journal.location"), isOn: Binding(
                    get: { enableLocationWeather },
                    set: { newValue in
                        if newValue {
                            LocationWeatherService.shared.requestPermission()
                        }
                        enableLocationWeather = newValue
                    }
                ))
                Text(String(localized: "settings.journal.location.desc"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if healthKit.isAvailable {
                    Toggle(String(localized: "settings.journal.healthkit"), isOn: Binding(
                        get: { enableHealthKit },
                        set: { newValue in
                            if newValue {
                                Task {
                                    let granted = await healthKit.requestAuthorization()
                                    enableHealthKit = granted
                                }
                            } else {
                                enableHealthKit = false
                            }
                        }
                    ))
                    Text(String(localized: "settings.journal.healthkit.desc"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Button(String(localized: "settings.journal.tags")) { showTagManagement = true }
                Button(String(localized: "settings.journal.notebooks")) { showJournalManagement = true }
            }

            Section(String(localized: "settings.reminders")) {
                Toggle(String(localized: "settings.reminders.daily"), isOn: Binding(
                    get: { reminder.isEnabled },
                    set: { newValue in
                        if newValue {
                            Task {
                                let granted = await reminder.requestPermission()
                                if granted {
                                    reminder.isEnabled = true
                                }
                            }
                        } else {
                            reminder.isEnabled = false
                        }
                    }
                ))

                if reminder.isEnabled {
                    DatePicker(
                        String(localized: "settings.reminders.time"),
                        selection: Binding(
                            get: { reminder.reminderTime },
                            set: { reminder.reminderTime = $0 }
                        ),
                        displayedComponents: .hourAndMinute
                    )
                }

                Text(String(localized: "settings.reminders.description"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section(String(localized: "settings.security")) {
                Toggle(String(format: String(localized: "settings.security.appLock"), appLock.biometricType.name), isOn: $appLock.isEnabled)
                if appLock.isEnabled {
                    Toggle(String(localized: "settings.security.lockSwitch"), isOn: $appLock.lockOnBackground)
                }
            }

            Section(String(localized: "settings.export")) {
                Picker(String(localized: "settings.export.format"), selection: $exportFormat) {
                    ForEach(ExportService.ExportFormat.allCases, id: \.self) { format in
                        Text(format.rawValue).tag(format)
                    }
                }

                ProButton(title: String(format: String(localized: "settings.export.all"), entries.count), icon: "square.and.arrow.up") {
                    exportEntries()
                }

                if let msg = exportMessage {
                    Text(msg)
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }

            Section(String(localized: "settings.backup")) {
                SecureField(String(localized: "settings.backup.password"), text: $backupPassword)
                    .textFieldStyle(.plain)

                ProButton(title: String(localized: "settings.backup.create"), icon: "lock.doc") {
                    createBackup()
                }

                Button {
                    showRestoreFilePicker = true
                } label: {
                    Label(String(localized: "settings.backup.restore"), systemImage: "arrow.down.doc")
                }

                if let msg = backupMessage {
                    Text(msg)
                        .font(.caption)
                        .foregroundStyle(.green)
                }

                if let msg = restoreMessage {
                    Text(msg)
                        .font(.caption)
                        .foregroundStyle(restoreIsError ? .red : .green)
                }

                Text(String(localized: "settings.backup.note"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section(String(localized: "settings.privacy")) {
                HStack {
                    Image(systemName: "lock.shield")
                        .foregroundStyle(.green)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(String(localized: "settings.privacy.title"))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text(String(localized: "settings.privacy.description"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section(String(localized: "settings.about")) {
                HStack {
                    Text(String(localized: "settings.version"))
                    Spacer()
                    Text("0.1.0")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text(String(localized: "settings.developer"))
                    Spacer()
                    Text("Jason Ye")
                        .foregroundStyle(.secondary)
                }
                Button(String(localized: "settings.rate")) { requestReview() }
                Link("GitHub", destination: URL(string: "https://github.com/JasonYeYuhe/Kinen")!)
                Link("Privacy Policy", destination: URL(string: "https://jasonyeyuhe.github.io/Kinen/")!)
                Link("Terms of Use", destination: URL(string: "https://jasonyeyuhe.github.io/Kinen/")!)
            }
        }
        .formStyle(.grouped)
        .navigationTitle(String(localized: "settings.title"))
        .sheet(isPresented: $showTagManagement) {
            TagManagementSheet()
        }
        .sheet(isPresented: $showJournalManagement) {
            JournalManagementSheet()
        }
        .fileImporter(
            isPresented: $showRestoreFilePicker,
            allowedContentTypes: [.data],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    pendingRestoreURL = url
                    showRestorePasswordPrompt = true
                }
            case .failure(let error):
                restoreIsError = true
                restoreMessage = String(format: String(localized: "settings.backup.restoreFailed"), error.localizedDescription)
            }
        }
        .alert(String(localized: "settings.backup.enterPassword"), isPresented: $showRestorePasswordPrompt) {
            SecureField(String(localized: "settings.backup.password"), text: $restorePassword)
            Button(String(localized: "general.cancel"), role: .cancel) {
                restorePassword = ""
                pendingRestoreURL = nil
            }
            Button(String(localized: "settings.backup.restore")) {
                previewRestore()
            }
        } message: {
            Text(String(localized: "settings.backup.enterPasswordMsg"))
        }
        .alert(String(localized: "settings.backup.confirmRestore"), isPresented: $showRestoreConfirmation) {
            Button(String(localized: "general.cancel"), role: .cancel) {
                restorePassword = ""
                pendingRestoreData = nil
                restorePreview = nil
            }
            Button(String(localized: "settings.backup.restore")) {
                executeRestore()
            }
        } message: {
            if let preview = restorePreview {
                Text(String(format: String(localized: "settings.backup.previewMsg"),
                    preview.entryCount, preview.tagCount,
                    preview.deviceName,
                    preview.createdAt.formatted(date: .abbreviated, time: .shortened)))
            }
        }
    }

    private func exportEntries() {
        #if os(macOS)
        ExportService.exportWithDialog(entries: entries, format: exportFormat)
        exportMessage = String(format: String(localized: "settings.export.done"), entries.count, exportFormat.rawValue)
        #else
        if let url = ExportService.exportAll(entries: entries, format: exportFormat) {
            exportMessage = String(format: String(localized: "settings.export.doneTo"), url.lastPathComponent)
        }
        #endif
    }

    private func requestReview() {
        requestReviewAction()
    }

    private func previewRestore() {
        guard let url = pendingRestoreURL, !restorePassword.isEmpty else {
            restoreIsError = true
            restoreMessage = String(localized: "settings.backup.noFileOrPassword")
            return
        }
        do {
            let accessing = url.startAccessingSecurityScopedResource()
            defer { if accessing { url.stopAccessingSecurityScopedResource() } }
            let data = try Data(contentsOf: url)
            let preview = try BackupService.previewBackup(data: data, password: restorePassword)
            pendingRestoreData = data
            restorePreview = preview
            showRestoreConfirmation = true
        } catch {
            restoreIsError = true
            restoreMessage = String(format: String(localized: "settings.backup.restoreFailed"), error.localizedDescription)
            restorePassword = ""
            pendingRestoreURL = nil
        }
    }

    private func executeRestore() {
        guard let data = pendingRestoreData else { return }
        defer {
            restorePassword = ""
            pendingRestoreURL = nil
            pendingRestoreData = nil
            restorePreview = nil
        }
        do {
            let count = try BackupService.restoreBackup(data: data, password: restorePassword, context: modelContext)
            restoreIsError = false
            restoreMessage = String(format: String(localized: "settings.backup.restored"), count)
        } catch {
            restoreIsError = true
            restoreMessage = String(format: String(localized: "settings.backup.restoreFailed"), error.localizedDescription)
        }
    }

    private func createBackup() {
        guard !backupPassword.isEmpty else {
            backupMessage = String(localized: "settings.backup.needPassword")
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
            backupMessage = String(format: String(localized: "settings.backup.created"), filename, data.count / 1024)
        } catch {
            backupMessage = String(format: String(localized: "settings.backup.failed"), error.localizedDescription)
        }
    }
}
