import SwiftUI
import SwiftData
import WidgetKit
import OSLog

private let logger = Logger(subsystem: "com.jasonye.kinen", category: "App")

@main
struct KinenApp: App {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @AppStorage("iCloudSyncEnabled") private var iCloudSyncEnabled = false
    @AppStorage("appearanceMode") private var appearanceMode = 0  // 0=system, 1=light, 2=dark
    @State private var appLock = AppLockService.shared
    @State private var containerError: String?

    private var colorScheme: ColorScheme? {
        switch appearanceMode {
        case 1: return .light
        case 2: return .dark
        default: return nil
        }
    }

    let container: ModelContainer

    init() {
        UserDefaults.standard.register(defaults: [
            "enableAutoSentiment": true,
            "enableAutoTags": true,
            "defaultMoodEnabled": true,
            "iCloudSyncEnabled": false,
        ])

        let schema = Schema([
            JournalEntry.self,
            Tag.self,
            EntryInsight.self,
            WritingSession.self,
            Journal.self,
        ])
        // CloudKit disabled — entitlements not configured in Developer Portal yet
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none
        )
        do {
            self.container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            logger.error("ModelContainer creation failed: \(error)")
            // Last-resort in-memory fallback to avoid crash-on-launch
            let memoryConfig = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: true,
                cloudKitDatabase: .none
            )
            self.container = try! ModelContainer(for: schema, configurations: [memoryConfig])
            _containerError = State(initialValue: "Database error: \(error.localizedDescription)")
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
            .preferredColorScheme(colorScheme)
        }
        .modelContainer(container)

        #if os(macOS)
        Settings {
            SettingsView()
                .preferredColorScheme(colorScheme)
        }
        .modelContainer(container)
        #endif
    }

    private func updateWidgetData() {
        WidgetDataProvider.syncAndReload(from: container.mainContext)
    }
}
