import SwiftUI
import SwiftData

/// Manage journal notebooks — create, rename, delete.
struct JournalManagementSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Journal.createdAt) private var journals: [Journal]

    @State private var showCreateSheet = false

    var body: some View {
        NavigationStack {
            List {
                if journals.isEmpty {
                    ContentUnavailableView {
                        Label(String(localized: "journals.empty.title"), systemImage: "books.vertical")
                    } description: {
                        Text(String(localized: "journals.empty.description"))
                    }
                } else {
                    ForEach(journals) { journal in
                        HStack(spacing: 12) {
                            Image(systemName: journal.icon)
                                .foregroundStyle(journal.color)
                                .frame(width: 28)

                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text(journal.name)
                                        .font(.body)
                                    if journal.isDefault {
                                        Text(String(localized: "journals.default"))
                                            .font(.caption2)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(.purple.opacity(0.1))
                                            .clipShape(Capsule())
                                    }
                                }
                                Text(String(format: String(localized: "journals.entryCount.%lld"), journal.entryCount))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .swipeActions(edge: .trailing) {
                            if !journal.isDefault {
                                Button(role: .destructive) {
                                    modelContext.delete(journal)
                                } label: {
                                    Label(String(localized: "general.delete"), systemImage: "trash")
                                }
                            }
                        }
                    }
                }

                // Presets section
                Section(String(localized: "journals.quickAdd")) {
                    ForEach(availablePresets, id: \.name) { preset in
                        Button {
                            let journal = Journal(name: preset.name, icon: preset.icon, colorHex: preset.color)
                            modelContext.insert(journal)
                        } label: {
                            Label(preset.name, systemImage: preset.icon)
                        }
                    }
                }
            }
            .navigationTitle(String(localized: "journals.manage"))
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "general.done")) { dismiss() }
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 340, idealWidth: 400, minHeight: 300, idealHeight: 400)
        #endif
    }

    private var availablePresets: [(name: String, icon: String, color: String)] {
        let existingNames = Set(journals.map(\.name))
        return Journal.presets.filter { !existingNames.contains($0.name) }
    }
}
