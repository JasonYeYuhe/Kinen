import SwiftUI

struct MoodPicker: View {
    @Binding var selectedMood: Mood?

    var body: some View {
        HStack(spacing: 16) {
            ForEach(Mood.allCases) { mood in
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        if selectedMood == mood {
                            selectedMood = nil // deselect
                        } else {
                            selectedMood = mood
                        }
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
