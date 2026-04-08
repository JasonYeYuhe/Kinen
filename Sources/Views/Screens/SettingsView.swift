import SwiftUI

struct SettingsView: View {
    @AppStorage("enableAutoSentiment") private var enableAutoSentiment = true
    @AppStorage("enableAutoTags") private var enableAutoTags = true
    @AppStorage("defaultMoodEnabled") private var defaultMoodEnabled = true
    @AppStorage("language") private var language = "system"

    var body: some View {
        Form {
            Section("AI Analysis") {
                Toggle("Auto-analyze sentiment", isOn: $enableAutoSentiment)
                Toggle("Auto-suggest tags", isOn: $enableAutoTags)
                Text("All AI analysis runs locally on your device. No data is sent anywhere.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Journal") {
                Toggle("Show mood picker for new entries", isOn: $defaultMoodEnabled)
            }

            Section("Privacy") {
                HStack {
                    Image(systemName: "lock.shield")
                        .foregroundStyle(.green)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Your Data is Private")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("All journal entries are stored locally on this device. No cloud sync, no tracking, no analytics.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("0.1.0")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Developer")
                    Spacer()
                    Text("Jason Ye")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Settings")
    }
}
