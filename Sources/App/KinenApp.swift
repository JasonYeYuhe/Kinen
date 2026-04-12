import SwiftUI
import SwiftData
import WidgetKit
import OSLog

private let logger = Logger(subsystem: "com.jasonye.kinen", category: "App")

@main
struct KinenApp: App {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @AppStorage("iCloudSyncEnabled") private var iCloudSyncEnabled = true
    @State private var appLock = AppLockService.shared
    @State private var containerError: String?

    init() {
        UserDefaults.standard.register(defaults: [
            "enableAutoSentiment": true,
            "enableAutoTags": true,
            "defaultMoodEnabled": true,
            "iCloudSyncEnabled": true,
        ])
    }

    var sharedModelContainer: ModelContainer {
        let schema = Schema([
            JournalEntry.self,
            Tag.self,
            EntryInsight.self,
            WritingSession.self
        ])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: iCloudSyncEnabled ? .automatic : .none
        )
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            logger.error("CloudKit ModelContainer failed: \(error). Falling back to local-only storage.")
            let localConfig = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .none
            )
            do {
                return try ModelContainer(for: schema, configurations: [localConfig])
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if !hasSeenOnboarding {
                    OnboardingView()
                } else if appLock.isLocked {
                    LockScreenView()
                } else {
                    ContentView()
                }
            }
            #if os(macOS)
            .onReceive(NotificationCenter.default.publisher(for: NSApplication.didResignActiveNotification)) { _ in
                appLock.lock()
            }
            #else
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
                appLock.lock()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                updateWidgetData()
            }
            #endif
            .task { updateWidgetData() }
        }
        .modelContainer(sharedModelContainer)

        #if os(macOS)
        Settings {
            SettingsView()
        }
        .modelContainer(sharedModelContainer)
        #endif
    }

    // MARK: - Widget Data

    private func updateWidgetData() {
        let context = sharedModelContainer.mainContext
        let descriptor = FetchDescriptor<JournalEntry>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        guard let entries = try? context.fetch(descriptor) else { return }

        let calendar = Calendar.current
        let dates = Set(entries.map { calendar.startOfDay(for: $0.createdAt) })
        let streak = Date().startOfDay.consecutiveDays(in: dates)

        let recentMoods: [(date: Date, value: Double)] = entries.prefix(7).compactMap { entry in
            guard let mood = entry.mood else { return nil }
            return (date: entry.createdAt, value: mood.normalizedValue)
        }

        let moods = entries.compactMap { $0.mood }
        let avgEmoji: String
        if moods.isEmpty {
            avgEmoji = "😐"
        } else {
            let avg = Double(moods.map { $0.rawValue }.reduce(0, +)) / Double(moods.count)
            avgEmoji = Mood(rawValue: Int(avg.rounded()))?.emoji ?? "😐"
        }

        WidgetDataProvider.updateWidgetData(
            streak: streak,
            totalEntries: entries.count,
            averageMoodEmoji: avgEmoji,
            recentMoods: recentMoods
        )
    }
}
