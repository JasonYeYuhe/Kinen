import SwiftUI
import SwiftData

@main
struct KinenApp: App {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var appLock = AppLockService.shared

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
        .modelContainer(for: [JournalEntry.self, Tag.self, EntryInsight.self, WritingSession.self])

        #if os(macOS)
        Settings {
            SettingsView()
        }
        #endif
    }
}
