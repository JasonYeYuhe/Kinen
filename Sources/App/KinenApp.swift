import SwiftUI
import SwiftData

@main
struct KinenApp: App {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some Scene {
        WindowGroup {
            if hasSeenOnboarding {
                ContentView()
            } else {
                OnboardingView()
            }
        }
        .modelContainer(for: [JournalEntry.self, Tag.self, EntryInsight.self, WritingSession.self])

        #if os(macOS)
        Settings {
            SettingsView()
        }
        #endif
    }
}
