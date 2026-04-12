import SwiftUI

/// Main watch view — quick mood check-in + today's summary.
struct WatchHomeView: View {
    @State private var selectedMood: WatchMood?
    @State private var quickNote = ""
    @State private var showConfirmation = false
    @State private var todayMoodCount = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Today's status
                    if todayMoodCount > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.caption2)
                            Text("\(todayMoodCount) check-in\(todayMoodCount == 1 ? "" : "s") today")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }

                    // Mood picker
                    Text("How are you feeling?")
                        .font(.headline)

                    HStack(spacing: 8) {
                        ForEach(WatchMood.allCases) { mood in
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    selectedMood = mood
                                }
                            } label: {
                                Text(mood.emoji)
                                    .font(.title3)
                                    .scaleEffect(selectedMood == mood ? 1.3 : 1.0)
                                    .opacity(selectedMood == nil || selectedMood == mood ? 1.0 : 0.4)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    if selectedMood != nil {
                        // Quick note
                        TextField("Quick note...", text: $quickNote)
                            .textFieldStyle(.plain)
                            .font(.caption)

                        // Save button
                        Button {
                            saveCheckIn()
                        } label: {
                            Label("Save", systemImage: "checkmark")
                                .font(.caption)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.purple)
                    }
                }
                .padding()
            }
            .navigationTitle("Kinen")
            .navigationBarTitleDisplayMode(.inline)
            .overlay {
                if showConfirmation {
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.largeTitle)
                            .foregroundStyle(.green)
                        Text("Saved!")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.ultraThinMaterial)
                    .transition(.opacity)
                }
            }
        }
    }

    private func saveCheckIn() {
        guard let mood = selectedMood else { return }

        // Save to shared UserDefaults for the iPhone app to pick up
        let defaults = UserDefaults(suiteName: "group.com.jasonye.kinen")
        var checkIns = (defaults?.array(forKey: "watch.pendingCheckIns") as? [[String: Any]]) ?? []
        checkIns.append([
            "mood": mood.rawValue,
            "note": quickNote,
            "date": Date().timeIntervalSince1970,
        ])
        defaults?.set(checkIns, forKey: "watch.pendingCheckIns")

        todayMoodCount += 1
        withAnimation { showConfirmation = true }

        // Reset after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                showConfirmation = false
                selectedMood = nil
                quickNote = ""
            }
        }
    }
}

// MARK: - Watch Mood (lightweight, no SwiftData dependency)

enum WatchMood: Int, CaseIterable, Identifiable {
    case terrible = 1, bad, neutral, good, great

    var id: Int { rawValue }

    var emoji: String {
        switch self {
        case .terrible: "😢"
        case .bad: "😔"
        case .neutral: "😐"
        case .good: "🙂"
        case .great: "😄"
        }
    }
}
