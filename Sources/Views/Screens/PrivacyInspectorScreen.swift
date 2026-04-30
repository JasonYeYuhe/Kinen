import SwiftUI

/// Privacy Inspector — a single screen the user (and an App Reviewer) can open to
/// see exactly where every kind of data the app handles goes. Reachable from
/// Settings → Privacy → tap the privacy row.
///
/// The content is intentionally a series of explicit positive and negative
/// statements so a reader can verify Kinen does not contact any third-party
/// AI service.
struct PrivacyInspectorScreen: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header

                section(
                    icon: "doc.text.fill",
                    color: .purple,
                    title: String(localized: "privacy.inspector.journal.title"),
                    body: String(localized: "privacy.inspector.journal.body")
                )

                section(
                    icon: "brain.head.profile",
                    color: .pink,
                    title: String(localized: "privacy.inspector.ai.title"),
                    body: String(localized: "privacy.inspector.ai.body")
                )

                section(
                    icon: "location.fill",
                    color: .blue,
                    title: String(localized: "privacy.inspector.location.title"),
                    body: String(localized: "privacy.inspector.location.body")
                )

                section(
                    icon: "cloud.sun.fill",
                    color: .cyan,
                    title: String(localized: "privacy.inspector.weather.title"),
                    body: String(localized: "privacy.inspector.weather.body")
                )

                section(
                    icon: "heart.fill",
                    color: .red,
                    title: String(localized: "privacy.inspector.health.title"),
                    body: String(localized: "privacy.inspector.health.body")
                )

                section(
                    icon: "creditcard.fill",
                    color: .green,
                    title: String(localized: "privacy.inspector.purchases.title"),
                    body: String(localized: "privacy.inspector.purchases.body")
                )

                neverDoCard

                Link(destination: URL(string: "https://jasonyeyuhe.github.io/Kinen/privacy.html")!) {
                    HStack {
                        Image(systemName: "doc.text.magnifyingglass")
                        Text(String(localized: "privacy.inspector.fullPolicy"))
                            .fontWeight(.medium)
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .font(.caption)
                    }
                    .padding()
                    .background(Color.purple.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.purple)
            }
            .padding()
        }
        .navigationTitle(String(localized: "privacy.inspector.title"))
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "privacy.inspector.heading"))
                .font(.title2)
                .fontWeight(.bold)
            Text(String(localized: "privacy.inspector.subheading"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func section(icon: String, color: Color, title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(color)
                    .clipShape(RoundedRectangle(cornerRadius: 7))
                Text(title)
                    .font(.headline)
            }
            Text(body)
                .font(.callout)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var neverDoCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "xmark.shield.fill")
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(Color.gray)
                    .clipShape(RoundedRectangle(cornerRadius: 7))
                Text(String(localized: "privacy.inspector.never.title"))
                    .font(.headline)
            }
            VStack(alignment: .leading, spacing: 6) {
                neverRow(String(localized: "privacy.inspector.never.serverText"))
                neverRow(String(localized: "privacy.inspector.never.thirdPartyAI"))
                neverRow(String(localized: "privacy.inspector.never.ads"))
                neverRow(String(localized: "privacy.inspector.never.analytics"))
                neverRow(String(localized: "privacy.inspector.never.tracking"))
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func neverRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(.red.opacity(0.7))
                .font(.caption)
                .padding(.top, 2)
            Text(text)
                .font(.callout)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    NavigationStack {
        PrivacyInspectorScreen()
    }
}
