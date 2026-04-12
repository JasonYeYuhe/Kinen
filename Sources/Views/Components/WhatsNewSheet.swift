import SwiftUI

struct WhatsNewSheet: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("lastSeenVersion") private var lastSeenVersion = ""

    static let currentVersion = "0.1.0"

    static var shouldShow: Bool {
        UserDefaults.standard.string(forKey: "lastSeenVersion") != currentVersion
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 40))
                            .foregroundStyle(.purple)
                        Text("What's New in Kinen")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Version \(Self.currentVersion)")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top)

                    Divider()

                    // Features
                    ChangelogItem(icon: "icloud.fill", color: .cyan, title: "iCloud Sync", description: "Your journal now syncs seamlessly across all your Apple devices.")
                    ChangelogItem(icon: "crown.fill", color: .purple, title: "Kinen Pro", description: "Unlock advanced AI analysis, exports, and more with a Pro subscription.")
                    ChangelogItem(icon: "lock.doc.fill", color: .green, title: "Encrypted Backup", description: "Create AES-256 encrypted backups of your journal. Your password, your data.")
                    ChangelogItem(icon: "tag.fill", color: .blue, title: "Tag Management", description: "Create, rename, merge, and delete tags. Full control over your organization.")
                    ChangelogItem(icon: "line.3.horizontal.decrease.circle", color: .orange, title: "Smart Filters", description: "Filter entries by mood, tags, date range, or bookmarks.")
                    ChangelogItem(icon: "calendar.badge.clock", color: .pink, title: "Year Heatmap", description: "GitHub-style year view shows your journaling patterns at a glance.")
                }
                .padding()
            }
            .navigationTitle("What's New")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        lastSeenVersion = Self.currentVersion
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 360, idealWidth: 420, minHeight: 400, idealHeight: 480)
        #else
        .presentationDetents([.medium, .large])
        #endif
    }
}

struct ChangelogItem: View {
    let icon: String
    let color: Color
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
