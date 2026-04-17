import SwiftUI

struct WhatsNewSheet: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("lastSeenVersion") private var lastSeenVersion = ""

    static let currentVersion = "0.3.0"

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
                        Text(String(localized: "whatsnew.title"))
                            .font(.title2)
                            .fontWeight(.bold)
                        Text(String(format: String(localized: "whatsnew.version.%@"), Self.currentVersion))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top)

                    Divider()

                    // Features
                    ChangelogItem(icon: "heart.text.square", color: .purple, title: String(localized: "whatsnew.therapistPack.title"), description: String(localized: "whatsnew.therapistPack.desc"))
                    ChangelogItem(icon: "sparkles", color: .pink, title: String(localized: "whatsnew.moodAI.title"), description: String(localized: "whatsnew.moodAI.desc"))
                    ChangelogItem(icon: "pin.fill", color: .orange, title: String(localized: "whatsnew.pin.title"), description: String(localized: "whatsnew.pin.desc"))
                    ChangelogItem(icon: "moon.stars.fill", color: .indigo, title: String(localized: "whatsnew.appearance.title"), description: String(localized: "whatsnew.appearance.desc"))
                    ChangelogItem(icon: "flame.fill", color: .red, title: String(localized: "whatsnew.streak2.title"), description: String(localized: "whatsnew.streak2.desc"))
                }
                .padding()
            }
            .navigationTitle(String(localized: "whatsnew.nav"))
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "general.done")) {
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
