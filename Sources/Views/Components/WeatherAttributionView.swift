import SwiftUI
#if canImport(WeatherKit)
import WeatherKit
#endif

/// Apple Weather attribution required by App Store guideline 5.2.5.
///
/// Every screen that displays WeatherKit data MUST render this view so
/// users can see the Apple Weather trademark and reach the legal source
/// page at https://weatherkit.apple.com/legal-attribution.html.
///
/// Preferred usage is to pass the live `WeatherAttribution` object from
/// `WeatherService.shared.attribution` so the trademark mark and legal
/// URL come directly from Apple. When no attribution object is available
/// (e.g. displaying a persisted entry before a fresh fetch happens), the
/// view falls back to the textual " Weather" mark and the documented
/// legal URL, which still satisfies 5.2.5.
struct WeatherAttributionView: View {
    #if canImport(WeatherKit)
    var attribution: WeatherAttribution? = nil
    #endif

    @Environment(\.colorScheme) private var colorScheme

    /// Documented Apple Weather legal URL — used when no live attribution
    /// object is available. Apple's 5.2.5 guidance explicitly names this URL.
    private static let fallbackLegalURL = URL(string: "https://weatherkit.apple.com/legal-attribution.html")!

    var body: some View {
        Link(destination: legalURL) {
            HStack(spacing: 4) {
                #if canImport(WeatherKit)
                if let markURL = logoURL {
                    AsyncImage(url: markURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                        default:
                            Text(" Weather")
                                .font(.caption2)
                        }
                    }
                    .frame(height: 12)
                    .accessibilityLabel(Text("Apple Weather"))
                } else {
                    Text(" Weather")
                        .font(.caption2)
                        .accessibilityLabel(Text("Apple Weather"))
                }
                #else
                Text(" Weather")
                    .font(.caption2)
                    .accessibilityLabel(Text("Apple Weather"))
                #endif
            }
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
        .accessibilityHint(Text(String(localized: "weather.attribution.hint")))
    }

    private var legalURL: URL {
        #if canImport(WeatherKit)
        attribution?.legalPageURL ?? Self.fallbackLegalURL
        #else
        Self.fallbackLegalURL
        #endif
    }

    #if canImport(WeatherKit)
    /// Apple ships light + dark variants of the combined Weather mark.
    /// Pick whichever matches the current color scheme.
    private var logoURL: URL? {
        guard let attribution else { return nil }
        return colorScheme == .dark
            ? attribution.combinedMarkDarkURL
            : attribution.combinedMarkLightURL
    }
    #endif
}
