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

        var displayName: String {
            switch self {
            case .last7: String(localized: "handoff.range.last7")
            case .last30: String(localized: "handoff.range.last30")
            case .last90: String(localized: "handoff.range.last90")
            case .allTime: String(localized: "handoff.range.allTime")
            }
        }

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
            .navigationTitle(String(localized: "handoff.title"))
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "general.done")) { dismiss() }
                }
                ToolbarItemGroup(placement: .primaryAction) {
                    Button(String(localized: "handoff.generate")) { generate() }
                        .buttonStyle(.borderedProminent)
                        .tint(.purple)
                }
            }
            .alert(String(localized: "handoff.alert.exportFailed"), isPresented: .constant(exportError != nil)) {
                Button(String(localized: "general.ok")) { exportError = nil }
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
                Text(String(localized: "handoff.disclaimer"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } icon: {
                Image(systemName: "lock.shield")
                    .foregroundStyle(.purple)
            }
        }
    }

    private var configurationSection: some View {
        Section(String(localized: "handoff.section.timeRange")) {
            Picker(String(localized: "handoff.picker.range"), selection: $rangeOption) {
                ForEach(RangeOption.allCases) { option in
                    HStack {
                        Text(option.displayName)
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
        Section(String(localized: "handoff.section.include")) {
            Toggle(String(localized: "handoff.toggle.overview"), isOn: $sections.overview)
            Toggle(String(localized: "handoff.toggle.moodData"), isOn: $sections.moodTrend)
            Toggle(String(localized: "handoff.toggle.themes"), isOn: $sections.topThemes)
            Toggle(String(localized: "handoff.toggle.patterns"), isOn: $sections.cognitiveDistortions)
            Toggle(String(localized: "handoff.toggle.entries"), isOn: $sections.highlightedEntries)
            Toggle(String(localized: "handoff.toggle.crisis"), isOn: $sections.crisisFlags)
        }
    }

    private var topicsSection: some View {
        Section {
            TextField(String(localized: "handoff.topics.placeholder"), text: $userTopics, axis: .vertical)
                .lineLimit(3...6)
        } header: {
            Text(String(localized: "handoff.topics.header"))
        } footer: {
            Text(String(localized: "handoff.topics.footer"))
        }
    }

    @ViewBuilder
    private func previewSection(_ report: HandoffReport) -> some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                summaryRow(String(localized: "handoff.preview.entries"), "\(report.overview.totalEntries)")
                summaryRow(String(localized: "handoff.preview.writingDays"), "\(report.overview.writingDays)")
                if let avg = report.overview.averageMood {
                    summaryRow(String(localized: "handoff.preview.avgMood"), String(format: "%.1f / 5", avg))
                }
                if !report.topThemes.isEmpty {
                    summaryRow(String(localized: "handoff.preview.topThemes"), report.topThemes.prefix(3).map(\.name).joined(separator: ", "))
                }
                if !report.cognitiveDistortions.isEmpty {
                    summaryRow(String(localized: "handoff.preview.patterns"), String(format: String(localized: "handoff.preview.patterns.count.%lld"), report.cognitiveDistortions.count))
                }
                if !report.crisisFlags.isEmpty {
                    summaryRow(String(localized: "handoff.preview.crisisFlags"), "\(report.crisisFlags.count)")
                        .foregroundStyle(.red)
                }
            }
            .padding(.vertical, 4)
        } header: {
            Text(String(localized: "handoff.section.preview"))
        }

        Section {
            Button {
                if isPro {
                    exportPDF(report)
                } else {
                    showPaywall = true
                }
            } label: {
                Label(isPro ? String(localized: "handoff.exportPDF") : String(localized: "handoff.exportPDF.pro"),
                      systemImage: isPro ? "doc.fill" : "lock.fill")
            }
            Button {
                exportMarkdown(report)
            } label: {
                Label(String(localized: "handoff.exportMarkdown"), systemImage: "doc.text")
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
            exportError = String(localized: "handoff.error.renderFailed")
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
            exportError = String(format: String(localized: "handoff.error.writeFailed.%@"), error.localizedDescription)
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
