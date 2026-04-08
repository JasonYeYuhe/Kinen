import SwiftUI
import SwiftData

@main
struct KinenApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [JournalEntry.self, Tag.self, EntryInsight.self])

        #if os(macOS)
        Settings {
            SettingsView()
        }
        #endif
    }
}
