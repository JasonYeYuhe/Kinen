import SwiftUI

/// Reusable Pro feature gate. Shows locked overlay with upgrade prompt.
struct ProGate<Content: View>: View {
    let feature: String
    var description: String? = nil
    @ViewBuilder let content: () -> Content
    @State private var showPaywall = false

    private var isPro: Bool { StoreService.shared.isPro }

    var body: some View {
        if isPro {
            content()
        } else {
            VStack(spacing: 12) {
                Image(systemName: "lock.fill")
                    .font(.title)
                    .foregroundStyle(.purple)
                Text(String(format: String(localized: "pro.requires"), feature))
                    .font(.subheadline)
                    .fontWeight(.medium)
                if let description {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }
                Button(String(localized: "pro.unlock.button")) { showPaywall = true }
                    .buttonStyle(.borderedProminent)
                    .tint(.purple)
                    .controlSize(.small)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.ultraThinMaterial)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(String(format: String(localized: "pro.requires"), feature))
            .accessibilityHint(String(localized: "pro.unlock.button"))
            .sheet(isPresented: $showPaywall) {
                ProPaywallView()
            }
        }
    }
}

/// Simple check + paywall trigger for buttons
struct ProButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    @State private var showPaywall = false

    private var isPro: Bool { StoreService.shared.isPro }

    var body: some View {
        Button(action: {
            if isPro { action() } else { showPaywall = true }
        }) {
            Label(title, systemImage: isPro ? icon : "lock.fill")
        }
        .sheet(isPresented: $showPaywall) {
            ProPaywallView()
        }
    }
}
