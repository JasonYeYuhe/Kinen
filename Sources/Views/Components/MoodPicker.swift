import SwiftUI

struct MoodPicker: View {
    @Binding var selectedMood: Mood?

    var body: some View {
        HStack(spacing: 16) {
            ForEach(Mood.allCases) { mood in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        if selectedMood == mood {
                            selectedMood = nil
                        } else {
                            selectedMood = mood
                        }
                        HapticManager.selection()
                    }
                }) {
                    VStack(spacing: 4) {
                        Text(mood.emoji)
                            .font(.system(size: selectedMood == mood ? 36 : 28))

                        Text(mood.label)
                            .font(.caption2)
                            .foregroundStyle(selectedMood == mood ? mood.color : .secondary)
                    }
                    .scaleEffect(selectedMood == mood ? 1.1 : 1.0)
                    .opacity(selectedMood == nil || selectedMood == mood ? 1.0 : 0.5)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 8)
    }
}
