import Foundation
import SwiftUI
import PDFKit
import OSLog

private let logger = Logger(subsystem: "com.jasonye.kinen", category: "HandoffPDF")

/// Renders a HandoffReport into a multi-page PDF using SwiftUI ImageRenderer.
/// Cross-platform (macOS + iOS); writes the PDF to a temporary URL.
@MainActor
enum HandoffPDFRenderer {

    /// US Letter: 8.5 x 11 inches at 72dpi
    static let pageSize = CGSize(width: 612, height: 792)
    static let margin: CGFloat = 48

    /// Render the report and write a PDF to the temp directory.
    /// Returns the URL on success, nil on failure.
    static func renderToTemporaryURL(_ report: HandoffReport) -> URL? {
        let renderer = ImageRenderer(content:
            HandoffReportPDFView(report: report)
                .frame(width: pageSize.width)
        )
        renderer.proposedSize = ProposedViewSize(width: pageSize.width, height: nil)

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("Kinen-Therapist-Handoff-\(Int(Date().timeIntervalSince1970)).pdf")

        var ok = false
        renderer.render { size, drawCallback in
            var mediaBox = CGRect(origin: .zero, size: pageSize)
            guard let consumer = CGDataConsumer(url: url as CFURL),
                  let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil)
            else {
                logger.error("Failed to create PDF context for handoff report")
                return
            }

            let pageCount = max(1, Int((size.height / pageSize.height).rounded(.up)))
            for pageIndex in 0..<pageCount {
                context.beginPDFPage(nil)

                // Flip Y for Core Graphics
                context.translateBy(x: 0, y: pageSize.height)
                context.scaleBy(x: 1, y: -1)

                // Translate so this page's slice of the content is in view
                context.translateBy(x: 0, y: -CGFloat(pageIndex) * pageSize.height)

                drawCallback(context)

                context.endPDFPage()
            }
            context.closePDF()
            ok = true
        }

        return ok ? url : nil
    }
}

/// SwiftUI view that lays out the handoff report contents for PDF rendering.
/// Width is fixed by the renderer; height grows with content.
struct HandoffReportPDFView: View {
    let report: HandoffReport

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    private static let datetimeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            header

            if report.overview.totalEntries > 0 {
                overviewSection
            }

            if !report.userTopics.isEmpty {
                section(title: "Topics I'd like to discuss") {
                    Text(report.userTopics)
                        .font(.system(size: 12))
                        .foregroundStyle(.primary)
                }
            }

            if !report.topThemes.isEmpty {
                section(title: "Recurring themes") {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(report.topThemes, id: \.name) { theme in
                            HStack {
                                Text(theme.name).font(.system(size: 12, weight: .medium))
                                Spacer()
                                Text("\(theme.count) entries")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            if !report.cognitiveDistortions.isEmpty {
                section(title: "Cognitive patterns observed",
                        subtitle: "Best-effort detection from journal text. Not a clinical diagnosis.") {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(report.cognitiveDistortions, id: \.name) { d in
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text(d.name).font(.system(size: 12, weight: .semibold))
                                    Spacer()
                                    Text("\(d.count) entries")
                                        .font(.system(size: 11))
                                        .foregroundStyle(.secondary)
                                }
                                if let example = d.exampleSentence {
                                    Text("\u{201C}\(example)\u{201D}")
                                        .font(.system(size: 11, design: .serif))
                                        .italic()
                                        .foregroundStyle(.secondary)
                                        .padding(.leading, 8)
                                }
                            }
                        }
                    }
                }
            }

            if !report.crisisFlags.isEmpty {
                section(title: "Concerning passages",
                        subtitle: "Flagged by on-device crisis detection. Please review with the writer.") {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(report.crisisFlags.indices, id: \.self) { idx in
                            let flag = report.crisisFlags[idx]
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text(Self.dateFormatter.string(from: flag.date))
                                        .font(.system(size: 11, weight: .medium))
                                    Spacer()
                                    Text(flag.severity.uppercased())
                                        .font(.system(size: 10, weight: .bold))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(flag.severity == "high" ? Color.red.opacity(0.15) : Color.orange.opacity(0.15))
                                        .foregroundStyle(flag.severity == "high" ? .red : .orange)
                                        .clipShape(Capsule())
                                }
                                Text("\u{201C}\(flag.snippet)\u{201D}")
                                    .font(.system(size: 11, design: .serif))
                                    .italic()
                                    .foregroundStyle(.primary)
                            }
                        }
                    }
                }
            }

            if !report.highlightedEntries.isEmpty {
                section(title: "Selected entries") {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(report.highlightedEntries.indices, id: \.self) { idx in
                            entryView(report.highlightedEntries[idx])
                        }
                    }
                }
            }

            footer
        }
        .padding(HandoffPDFRenderer.margin)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
    }

    // MARK: - Header / Footer

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Therapist Handoff")
                .font(.system(size: 24, weight: .bold))
            Text("\(Self.dateFormatter.string(from: report.dateRange.start)) – \(Self.dateFormatter.string(from: report.dateRange.end))")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
            Text("Generated by Kinen on \(Self.datetimeFormatter.string(from: report.generatedAt)) — all data stayed on device.")
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
                .padding(.top, 2)
            Divider().padding(.top, 6)
        }
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 4) {
            Divider()
            Text("This report was generated from on-device journal data. It is not a clinical diagnosis. Kinen is not a substitute for professional mental health care.")
                .font(.system(size: 9))
                .foregroundStyle(.tertiary)
        }
        .padding(.top, 8)
    }

    // MARK: - Overview

    private var overviewSection: some View {
        section(title: "Overview") {
            let o = report.overview
            VStack(alignment: .leading, spacing: 4) {
                statRow("Entries", "\(o.totalEntries) over \(report.dateRange.dayCount) days (\(o.writingDays) writing days)")
                statRow("Total words", "\(o.totalWords)")
                if let avg = o.averageMood {
                    statRow("Average mood", String(format: "%.2f / 5", avg))
                }
                if let s = o.averageSentiment {
                    statRow("Average sentiment", String(format: "%+.2f (range -1.0 to +1.0)", s))
                }
                if let high = o.highestMoodDay {
                    statRow("Highest mood", Self.dateFormatter.string(from: high))
                }
                if let low = o.lowestMoodDay {
                    statRow("Lowest mood", Self.dateFormatter.string(from: low))
                }
                if o.longestSilence > 1 {
                    statRow("Longest silence", "\(o.longestSilence) days between entries")
                }
            }
        }
    }

    private func statRow(_ key: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(key + ":")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 140, alignment: .leading)
            Text(value)
                .font(.system(size: 12))
            Spacer()
        }
    }

    // MARK: - Entry View

    private func entryView(_ entry: HandoffReport.HighlightedEntry) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(Self.dateFormatter.string(from: entry.date))
                    .font(.system(size: 12, weight: .semibold))
                if let title = entry.title, !title.isEmpty {
                    Text("— \(title)")
                        .font(.system(size: 12, weight: .medium))
                }
                Spacer()
            }
            HStack(spacing: 6) {
                Text(reasonLabel(entry.reason))
                    .font(.system(size: 10, weight: .medium))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.purple.opacity(0.12))
                    .foregroundStyle(.purple)
                    .clipShape(Capsule())
                if let mood = entry.mood {
                    Text("Mood \(mood)/5")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
                if let s = entry.sentiment {
                    Text(String(format: "Sentiment %+.2f", s))
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }
            Text(entry.snippet)
                .font(.system(size: 11, design: .serif))
                .foregroundStyle(.primary)
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.gray.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }

    private func reasonLabel(_ reason: HandoffReport.HighlightedEntry.HighlightReason) -> String {
        switch reason {
        case .lowestMood: "Lowest mood"
        case .highestMood: "Highest mood"
        case .largestDeviation: "Notable shift"
        case .crisis: "Crisis flag"
        case .userPinned: "Pinned"
        }
    }

    // MARK: - Section helper

    @ViewBuilder
    private func section<Content: View>(
        title: String,
        subtitle: String? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 16, weight: .bold))
            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .italic()
            }
            content()
        }
    }
}
