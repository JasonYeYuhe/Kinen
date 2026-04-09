import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedTab: AppTab = .journal
    @State private var selectedEntry: JournalEntry?

    var body: some View {
        #if os(macOS)
        NavigationSplitView {
            sidebar
        } detail: {
            detailView
        }
        .frame(minWidth: 800, minHeight: 500)
        #else
        TabView(selection: $selectedTab) {
            JournalListScreen(selectedEntry: $selectedEntry)
                .tabItem { Label("Journal", systemImage: "book.closed") }
                .tag(AppTab.journal)

            InsightsScreen()
                .tabItem { Label("Insights", systemImage: "chart.line.uptrend.xyaxis") }
                .tag(AppTab.insights)

            RecapScreen()
                .tabItem { Label("Recap", systemImage: "doc.text.magnifyingglass") }
                .tag(AppTab.recap)

            CalendarScreen()
                .tabItem { Label("Calendar", systemImage: "calendar") }
                .tag(AppTab.calendar)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .tag(AppTab.settings)
        }
        .tint(.purple)
        #endif
    }

    #if os(macOS)
    private var sidebar: some View {
        List(selection: $selectedTab) {
            Label("Journal", systemImage: "book.closed")
                .tag(AppTab.journal)
            Label("Insights", systemImage: "chart.line.uptrend.xyaxis")
                .tag(AppTab.insights)
            Label("Recap", systemImage: "doc.text.magnifyingglass")
                .tag(AppTab.recap)
            Label("Calendar", systemImage: "calendar")
                .tag(AppTab.calendar)
        }
        .listStyle(.sidebar)
        .frame(minWidth: 180)
    }

    @ViewBuilder
    private var detailView: some View {
        switch selectedTab {
        case .journal:
            JournalListScreen(selectedEntry: $selectedEntry)
        case .insights:
            InsightsScreen()
        case .recap:
            RecapScreen()
        case .calendar:
            CalendarScreen()
        case .settings:
            SettingsView()
        }
    }
    #endif
}

enum AppTab: String, Hashable {
    case journal
    case insights
    case recap
    case calendar
    case settings
}
