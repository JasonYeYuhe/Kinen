import SwiftUI
import SwiftData
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
            // Fallback: try local-only without CloudKit
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
            #endif
        }
        .modelContainer(sharedModelContainer)

        #if os(macOS)
        Settings {
            SettingsView()
        }
        .modelContainer(sharedModelContainer)
        #endif
    }
}
