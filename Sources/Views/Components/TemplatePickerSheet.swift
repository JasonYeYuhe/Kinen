import SwiftUI

struct TemplatePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onSelect: (JournalTemplate) -> Void

    var body: some View {
        #if os(macOS)
        macOSBody
        #else
        iOSBody
        #endif
    }

    private var grid: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(JournalTemplate.allCases) { template in
                    Button(action: {
                        onSelect(template)
                        dismiss()
                    }) {
                        VStack(spacing: 10) {
                            Image(systemName: template.icon)
                                .font(.title)
                                .foregroundStyle(template.color)
                                .frame(height: 36)

                            Text(template.name)
                                .font(.headline)
                                .foregroundStyle(.primary)

                            Text(template.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .lineLimit(3)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(template.color.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(template.color.opacity(0.2), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
    }

    #if os(macOS)
    private var macOSBody: some View {
        VStack(spacing: 0) {
            HStack {
                Text(String(localized: "template.choose"))
                    .font(.headline)
                Spacer()
                Button(String(localized: "general.cancel")) { dismiss() }
                    .keyboardShortcut(.cancelAction)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            Divider()
            grid
        }
        .frame(minWidth: 360, minHeight: 350)
    }
    #else
    private var iOSBody: some View {
        NavigationStack {
            grid
                .navigationTitle(String(localized: "template.choose"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(String(localized: "general.cancel")) { dismiss() }
                    }
                }
        }
    }
    #endif
}
