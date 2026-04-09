import SwiftUI

/// Reusable Pro feature gate. Shows locked overlay with upgrade prompt.
struct ProGate<Content: View>: View {
    let feature: String
    @ViewBuilder let content: () -> Content
    @State private var showPaywall = false

    private var isPro: Bool { StoreService.shared.isPro }

    var body: some View {
        if isPro {
            content()
        } else {
            content()
                .overlay {
                    VStack(spacing: 12) {
                        Image(systemName: "lock.fill")
                            .font(.title)
                            .foregroundStyle(.purple)
                        Text("\(feature) requires Pro")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Button("Unlock Pro") { showPaywall = true }
                            .buttonStyle(.borderedProminent)
                            .tint(.purple)
                            .controlSize(.small)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.ultraThinMaterial)
                }
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
