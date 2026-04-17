import SwiftUI
import SwiftData
#if canImport(AppKit)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif

/// Configure, preview and export a clinician handoff report.
/// Free users are limited to the last 7 days; Pro unlocks full history + PDF.
struct TherapistHandoffSheet: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \JournalEntry.createdAt, order: .reverse) private var entries: [JournalEntry]

    enum RangeOption: String, CaseIterable, Identifiable {
        case last7 = "Last 7 days"
        case last30 = "Last 30 days"
        case last90 = "Last 90 days"
        case allTime = "All time"

        var id: String { rawValue }

        /// Free users can only pick last7
        var requiresPro: Bool { self != .last7 }

        func dateRange(now: Date = Date()) -> HandoffReport.DateRange {
            let cal = Calendar.current
            let start: Date
            switch self {
            case .last7:
                start = cal.date(byAdding: .day, value: -7, to: now) ?? now
            case .last30:
                start = cal.date(byAdding: .day, value: -30, to: now) ?? now
            case .last90:
                start = cal.date(byAdding: .day, value: -90, to: now) ?? now
            case .allTime:
                start = .distantPast
            }
            return HandoffReport.DateRange(start: start, end: now)
        }
    }

    @State private var rangeOption: RangeOption = .last7
    @State private var sections = HandoffReport.Sections.all
    @State private var userTopics: String = ""
    @State private var report: HandoffReport?
    @State private var showPaywall = false
    @State private var exportError: String?
    @State private var pendingPDFURL: URL?
    @State private var showShare = false

    private var isPro: Bool { StoreService.shared.isPro }

    var body: some View {
        NavigationStack {
            Form {
                disclaimerSection
                configurationSection
                contentsSection
                topicsSection
                if let report {
                    previewSection(report)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Therapist Handoff")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItemGroup(placement: .primaryAction) {
                    Button("Generate") { generate() }
                        .buttonStyle(.borderedProminent)
                        .tint(.purple)
                }
            }
            .alert("Export failed", isPresented: .constant(exportError != nil)) {
                Button("OK") { exportError = nil }
            } message: {
                Text(exportError ?? "")
            }
            .sheet(isPresented: $showPaywall) {
                ProPaywallView()
            }
            #if os(iOS)
            .sheet(isPresented: $showShare) {
                if let url = pendingPDFURL {
                    ShareSheet(items: [url])
                }
            }
            #endif
        }
        #if os(macOS)
        .frame(minWidth: 520, idealWidth: 640, minHeight: 560, idealHeight: 720)
        #endif
    }

    // MARK: - Sections

    private var disclaimerSection: some View {
        Section {
            Label {
                Text("Generates a structured summary you can share with a clinician. All processing happens on this device — nothing leaves Kinen until you export.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } icon: {
                Image(systemName: "lock.shield")
                    .foregroundStyle(.purple)
            }
        }
    }

    private var configurationSection: some View {
        Section("Time range") {
            Picker("Range", selection: $rangeOption) {
                ForEach(RangeOption.allCases) { option in
                    HStack {
                        Text(option.rawValue)
                        if option.requiresPro && !isPro {
                            Image(systemName: "lock.fill")
                                .font(.caption2)
                                .foregroundStyle(.purple)
                        }
                    }
                    .tag(option)
                }
            }
            .onChange(of: rangeOption) { _, newValue in
                if newValue.requiresPro && !isPro {
                    showPaywall = true
                    rangeOption = .last7
                }
            }
        }
    }

    private var contentsSection: some View {
        Section("Include") {
            Toggle("Overview statistics", isOn: $sections.overview)
            Toggle("Mood data", isOn: $sections.moodTrend)
            Toggle("Recurring themes", isOn: $sections.topThemes)
            Toggle("Cognitive patterns", isOn: $sections.cognitiveDistortions)
            Toggle("Selected entries", isOn: $sections.highlightedEntries)
            Toggle("Crisis flags", isOn: $sections.crisisFlags)
        }
    }

    private var topicsSection: some View {
        Section {
            TextField("e.g. Work stress, sleep, relationship with my brother…", text: $userTopics, axis: .vertical)
                .lineLimit(3...6)
        } header: {
            Text("Topics I'd like to discuss")
        } footer: {
            Text("Optional. These appear at the top of the report so the clinician knows what's most on your mind.")
        }
    }

    @ViewBuilder
    private func previewSection(_ report: HandoffReport) -> some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                summaryRow("Entries", "\(report.overview.totalEntries)")
                summaryRow("Writing days", "\(report.overview.writingDays)")
                if let avg = report.overview.averageMood {
                    summaryRow("Avg mood", String(format: "%.1f / 5", avg))
                }
                if !report.topThemes.isEmpty {
                    summaryRow("Top themes", report.topThemes.prefix(3).map(\.name).joined(separator: ", "))
                }
                if !report.cognitiveDistortions.isEmpty {
                    summaryRow("Patterns", "\(report.cognitiveDistortions.count) detected")
                }
                if !report.crisisFlags.isEmpty {
                    summaryRow("Crisis flags", "\(report.crisisFlags.count)")
                        .foregroundStyle(.red)
                }
            }
            .padding(.vertical, 4)
        } header: {
            Text("Preview")
        }

        Section {
            Button {
                if isPro {
                    exportPDF(report)
                } else {
                    showPaywall = true
                }
            } label: {
                Label(isPro ? "Export as PDF" : "Export as PDF (Pro)",
                      systemImage: isPro ? "doc.fill" : "lock.fill")
            }
            Button {
                exportMarkdown(report)
            } label: {
                Label("Export as Markdown", systemImage: "doc.text")
            }
        }
    }

    private func summaryRow(_ key: String, _ value: String) -> some View {
        HStack {
            Text(key).foregroundStyle(.secondary)
            Spacer()
            Text(value).fontWeight(.medium)
        }
        .font(.subheadline)
    }

    // MARK: - Actions

    private func generate() {
        let range = rangeOption.dateRange()
        report = TherapistHandoffService.buildReport(
            from: entries,
            range: range,
            userTopics: userTopics,
            sections: sections
        )
        HapticManager.notification(.success)
    }

    private func exportPDF(_ report: HandoffReport) {
        guard let url = HandoffPDFRenderer.renderToTemporaryURL(report) else {
            exportError = "Could not render PDF."
            return
        }
        revealOrShare(url)
    }

    private func exportMarkdown(_ report: HandoffReport) {
        let md = TherapistHandoffService.renderMarkdown(report)
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("Kinen-Therapist-Handoff-\(Int(Date().timeIntervalSince1970)).md")
        do {
            try md.write(to: url, atomically: true, encoding: .utf8)
            revealOrShare(url)
        } catch {
            exportError = "Could not write file: \(error.localizedDescription)"
        }
    }

    private func revealOrShare(_ url: URL) {
        #if os(macOS)
        NSWorkspace.shared.activateFileViewerSelecting([url])
        #else
        pendingPDFURL = url
        showShare = true
        #endif
    }
}

#if os(iOS)
private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#endif
