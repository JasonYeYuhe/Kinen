import SwiftUI

struct TemplatePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onSelect: (JournalTemplate) -> Void

    var body: some View {
        NavigationStack {
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
            .navigationTitle(String(localized: "template.choose"))
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "general.cancel")) { dismiss() }
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 360, idealWidth: 420, minHeight: 350, idealHeight: 400)
        #endif
    }
}
