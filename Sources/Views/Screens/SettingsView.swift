import SwiftUI
import SwiftData
import StoreKit
import UniformTypeIdentifiers
#if canImport(WeatherKit)
import WeatherKit
#endif

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.requestReview) private var requestReviewAction
    @Query(sort: \JournalEntry.createdAt, order: .reverse) private var entries: [JournalEntry]

    @AppStorage("appearanceMode") private var appearanceMode = 0
    @AppStorage("enableAutoSentiment") private var enableAutoSentiment = true
    @AppStorage("enableAutoTags") private var enableAutoTags = true
    @AppStorage("defaultMoodEnabled") private var defaultMoodEnabled = true
    @AppStorage("enableLocationWeather") private var enableLocationWeather = false
    @AppStorage("enableHealthKit") private var enableHealthKit = false
    @AppStorage("dailyWordGoal") private var dailyWordGoal = 0
    @AppStorage("onThisDayEnabled") private var onThisDayEnabled = false
    @State private var healthKit = HealthKitService.shared
    @State private var locationWeather = LocationWeatherService.shared
    @State private var appLock = AppLockService.shared
    @State private var reminder = ReminderService.shared
    @State private var isFetchingLocation = false
    @State private var showExportPicker = false
    @State private var showTagManagement = false
    @State private var showJournalManagement = false
    @State private var exportFormat: ExportService.ExportFormat = .markdown
    @State private var exportMessage: String?
    @AppStorage("iCloudSyncEnabled") private var iCloudSyncEnabled = false
    @State private var backupPassword = ""
    @State private var backupMessage: String?
    @State private var showBackupPassword = false
    @AppStorage("lastBackupDate") private var lastBackupDateString = ""
    @AppStorage("backupReminderDismissed") private var backupReminderDismissed = ""
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

    // Sample Journal state
    @State private var sampleEntryCount: Int = 0
    @State private var sampleMessage: String?

    // Test Apple WeatherKit state
    @State private var isTestingWeatherKit = false
    @State private var weatherKitTestResult: WeatherKitTestResult?

    enum WeatherKitTestResult: Equatable {
        case success(city: String, weather: String)
        case failure(message: String)
    }

    var body: some View {
        Form {
            Section(String(localized: "settings.appearance")) {
                Picker(String(localized: "settings.appearance.mode"), selection: $appearanceMode) {
                    Text(String(localized: "settings.appearance.system")).tag(0)
                    Text(String(localized: "settings.appearance.light")).tag(1)
                    Text(String(localized: "settings.appearance.dark")).tag(2)
                }
                .pickerStyle(.segmented)
            }

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

                if enableLocationWeather {
                    locationStatusRow
                    weatherKitTestRow
                }
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
                Picker(String(localized: "settings.journal.wordGoal"), selection: $dailyWordGoal) {
                    Text(String(localized: "settings.journal.wordGoal.off")).tag(0)
                    Text("100").tag(100)
                    Text("250").tag(250)
                    Text("500").tag(500)
                    Text("1000").tag(1000)
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

                Toggle(String(localized: "settings.reminders.onThisDay"), isOn: $onThisDayEnabled)
                Text(String(localized: "settings.reminders.onThisDay.desc"))
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
                // Auto-backup reminder banner
                if shouldShowBackupReminder {
                    HStack {
                        Image(systemName: "exclamationmark.shield")
                            .foregroundStyle(.orange)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(String(localized: "settings.backup.reminder.title"))
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text(String(localized: "settings.backup.reminder.desc"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button {
                            dismissBackupReminder()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 4)
                }

                SecureField(String(localized: "settings.backup.password"), text: $backupPassword)
                    .textFieldStyle(.plain)

                // Password strength indicator
                if !backupPassword.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(0..<3, id: \.self) { i in
                            Capsule()
                                .fill(i < passwordStrength.level ? passwordStrength.color : Color.gray.opacity(0.3))
                                .frame(height: 4)
                        }
                        Text(passwordStrength.label)
                            .font(.caption2)
                            .foregroundStyle(passwordStrength.color)
                    }
                }

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
                NavigationLink {
                    PrivacyInspectorScreen()
                } label: {
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
            }

            Section(String(localized: "settings.sample.section")) {
                if sampleEntryCount > 0 {
                    HStack(spacing: 8) {
                        Image(systemName: "books.vertical")
                            .foregroundStyle(.purple)
                        Text(String(format: String(localized: "settings.sample.loaded"), sampleEntryCount))
                            .font(.subheadline)
                    }
                    Button(role: .destructive) {
                        clearSampleJournal()
                    } label: {
                        Label(String(localized: "settings.sample.clear"), systemImage: "trash")
                    }
                } else {
                    Button {
                        loadSampleJournal()
                    } label: {
                        Label(String(format: String(localized: "settings.sample.load"), SampleDataLoader.entryCount), systemImage: "books.vertical")
                    }
                    Text(String(localized: "settings.sample.note"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let msg = sampleMessage {
                    Text(msg)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section(String(localized: "settings.about")) {
                HStack {
                    Text(String(localized: "settings.version"))
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "")
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
        .onAppear { refreshSampleCount() }
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

    // MARK: - Password Strength

    private struct PasswordStrengthInfo {
        let level: Int // 1=weak, 2=medium, 3=strong
        let label: String
        let color: Color
    }

    private var passwordStrength: PasswordStrengthInfo {
        let pw = backupPassword
        let hasDigit = pw.rangeOfCharacter(from: .decimalDigits) != nil
        let hasUpper = pw.rangeOfCharacter(from: .uppercaseLetters) != nil
        let hasLower = pw.rangeOfCharacter(from: .lowercaseLetters) != nil
        if pw.count >= 10 && hasDigit && hasUpper && hasLower {
            return PasswordStrengthInfo(level: 3, label: String(localized: "settings.backup.strength.strong"), color: .green)
        } else if pw.count >= 6 {
            return PasswordStrengthInfo(level: 2, label: String(localized: "settings.backup.strength.medium"), color: .orange)
        } else {
            return PasswordStrengthInfo(level: 1, label: String(localized: "settings.backup.strength.weak"), color: .red)
        }
    }

    // MARK: - Auto-Backup Reminder

    private var shouldShowBackupReminder: Bool {
        guard entries.count > 10 else { return false }
        // Check if dismissed within last 7 days
        if let dismissDate = ISO8601DateFormatter().date(from: backupReminderDismissed),
           Date().timeIntervalSince(dismissDate) < 7 * 24 * 3600 {
            return false
        }
        // Check if last backup was >30 days ago (or never)
        if let lastDate = ISO8601DateFormatter().date(from: lastBackupDateString) {
            return Date().timeIntervalSince(lastDate) > 30 * 24 * 3600
        }
        return true // never backed up
    }

    private func dismissBackupReminder() {
        backupReminderDismissed = ISO8601DateFormatter().string(from: Date())
    }

    private func createBackup() {
        guard !backupPassword.isEmpty else {
            backupMessage = String(localized: "settings.backup.needPassword")
            return
        }
        guard backupPassword.count >= 6 else {
            backupMessage = String(localized: "settings.backup.tooShort")
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
            lastBackupDateString = ISO8601DateFormatter().string(from: Date())
            backupMessage = String(format: String(localized: "settings.backup.created"), filename, data.count / 1024)
        } catch {
            backupMessage = String(format: String(localized: "settings.backup.failed"), error.localizedDescription)
        }
    }

    // MARK: - Location status

    @ViewBuilder
    private var locationStatusRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: "location.fill")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                Text(locationStatusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                Spacer()
                Button {
                    Task { await fetchLocationNow() }
                } label: {
                    if isFetchingLocation {
                        ProgressView().controlSize(.small)
                    } else {
                        Text(String(localized: "settings.journal.location.fetchNow"))
                    }
                }
                .font(.caption)
                .buttonStyle(.bordered)
                .disabled(isFetchingLocation)
            }

            // WeatherKit attribution — REQUIRED by App Store 5.2.5 whenever
            // Apple Weather data is displayed. Shown only when weather data
            // is actually present in the status row.
            if locationWeather.currentWeather != nil {
                #if canImport(WeatherKit)
                WeatherAttributionView(attribution: locationWeather.weatherAttribution)
                #else
                WeatherAttributionView()
                #endif
            }
        }
    }

    private var locationStatusText: String {
        if let loc = locationWeather.currentLocation {
            if let weather = locationWeather.currentWeather {
                return "\(loc) · \(weather)"
            }
            return loc
        }
        switch locationWeather.authorizationStatus {
        case .denied, .restricted:
            return String(localized: "settings.journal.location.denied")
        case .notDetermined:
            return String(localized: "settings.journal.location.notRequested")
        default:
            return String(localized: "settings.journal.location.noData")
        }
    }

    private func fetchLocationNow() async {
        isFetchingLocation = true
        defer { isFetchingLocation = false }
        _ = await locationWeather.fetchLocationAndWeather()
    }

    // MARK: - Sample Journal

    private func refreshSampleCount() {
        sampleEntryCount = SampleDataLoader.sampleEntryCount(in: modelContext)
    }

    private func loadSampleJournal() {
        let inserted = SampleDataLoader.loadSampleEntries(into: modelContext)
        if inserted > 0 {
            sampleMessage = String(format: String(localized: "settings.sample.loadedToast"), inserted)
        } else {
            sampleMessage = String(localized: "settings.sample.alreadyLoaded")
        }
        refreshSampleCount()
    }

    private func clearSampleJournal() {
        let removed = SampleDataLoader.clearSampleEntries(from: modelContext)
        sampleMessage = String(format: String(localized: "settings.sample.clearedToast"), removed)
        refreshSampleCount()
    }

    // MARK: - Test Apple WeatherKit (separate from sample journal)

    @ViewBuilder
    private var weatherKitTestRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Button {
                    Task { await testAppleWeatherKit() }
                } label: {
                    if isTestingWeatherKit {
                        HStack(spacing: 6) {
                            ProgressView().controlSize(.small)
                            Text(String(localized: "settings.weatherkit.testing"))
                        }
                    } else {
                        Label(String(localized: "settings.weatherkit.test"), systemImage: "cloud.sun")
                    }
                }
                .disabled(isTestingWeatherKit)
                Spacer()
            }

            if let result = weatherKitTestResult {
                switch result {
                case .success(let city, let weather):
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.seal.fill").foregroundStyle(.green)
                            Text(String(localized: "settings.weatherkit.success"))
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        Text("\(city) · \(weather)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        #if canImport(WeatherKit)
                        WeatherAttributionView(attribution: locationWeather.weatherAttribution)
                        #else
                        WeatherAttributionView()
                        #endif
                        Button {
                            saveWeatherKitTestAsEntry(city: city, weather: weather)
                        } label: {
                            Label(String(localized: "settings.weatherkit.saveAsEntry"), systemImage: "square.and.pencil")
                                .font(.caption)
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.vertical, 4)
                case .failure(let message):
                    HStack(alignment: .top, spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                        Text(message)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                Text(String(localized: "settings.weatherkit.test.note"))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private func testAppleWeatherKit() async {
        isTestingWeatherKit = true
        weatherKitTestResult = nil
        defer { isTestingWeatherKit = false }

        // Step 1: gate on permission
        let status = locationWeather.authorizationStatus
        if status == .notDetermined {
            locationWeather.requestPermission()
            // Give the system a moment to update; we don't poll aggressively.
            try? await Task.sleep(nanoseconds: 800_000_000)
        }

        switch locationWeather.authorizationStatus {
        case .denied, .restricted:
            weatherKitTestResult = .failure(message: String(localized: "settings.weatherkit.error.permission"))
            return
        case .notDetermined:
            weatherKitTestResult = .failure(message: String(localized: "settings.weatherkit.error.notDetermined"))
            return
        default:
            break
        }

        // Step 2: live fetch
        let result = await locationWeather.fetchLocationAndWeather()
        if let city = result.location, let weather = result.weather {
            weatherKitTestResult = .success(city: city, weather: weather)
        } else {
            weatherKitTestResult = .failure(message: String(localized: "settings.weatherkit.error.fetchFailed"))
        }
    }

    private func saveWeatherKitTestAsEntry(city: String, weather: String) {
        let entry = JournalEntry(
            content: String(localized: "settings.weatherkit.testEntry.content"),
            title: String(localized: "settings.weatherkit.testEntry.title"),
            mood: nil,
            template: .freeWrite,
            createdAt: Date()
        )
        entry.location = city
        entry.weather = weather
        entry.latitude = locationWeather.currentLatitude
        entry.longitude = locationWeather.currentLongitude
        entry.isSampleData = false
        modelContext.insert(entry)
        try? modelContext.save()
        sampleMessage = String(localized: "settings.weatherkit.testEntry.saved")
    }
}
