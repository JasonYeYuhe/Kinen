import SwiftUI
import StoreKit

struct ProPaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var store = StoreService.shared
    @State private var purchaseError: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    featuresSection
                    pricingSection
                    legalSection
                }
                .padding()
            }
            .navigationTitle("Kinen Pro")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .alert("Purchase Error", isPresented: .constant(purchaseError != nil)) {
                Button("OK") { purchaseError = nil }
            } message: {
                Text(purchaseError ?? "")
            }
        }
        #if os(macOS)
        .frame(minWidth: 500, minHeight: 600)
        #endif
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "crown.fill")
                .font(.system(size: 48))
                .foregroundStyle(.purple.gradient)

            Text("Unlock Kinen Pro")
                .font(.title)
                .fontWeight(.bold)

            Text("Deep AI insights, iCloud sync, and more.\nAll processing stays on your device.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Features

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            ProFeatureRow(icon: "brain.head.profile", color: .purple, title: "Full AI Analysis", subtitle: "CBT reflections, pattern discovery, cognitive distortion detection")
            ProFeatureRow(icon: "chart.line.uptrend.xyaxis", color: .blue, title: "Advanced Insights", subtitle: "30/90-day mood trends, weekly & monthly AI recaps")
            ProFeatureRow(icon: "icloud.fill", color: .cyan, title: "iCloud Sync", subtitle: "Seamless sync across all your Apple devices")
            ProFeatureRow(icon: "square.and.arrow.up", color: .green, title: "Export & Backup", subtitle: "Markdown, JSON, encrypted backup with AES-256")
            ProFeatureRow(icon: "doc.text", color: .orange, title: "All 8 Templates", subtitle: "CBT three-column, dream journal, goal reflection & more")
            ProFeatureRow(icon: "sparkles", color: .pink, title: "Smart Prompts", subtitle: "AI-powered writing suggestions based on your mood & history")
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Pricing

    private var pricingSection: some View {
        VStack(spacing: 12) {
            if store.isLoading {
                ProgressView("Loading prices...")
            } else if store.products.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.title2)
                        .foregroundStyle(.orange)
                    Text("Could not load products")
                        .font(.subheadline)
                    if let error = store.loadError {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Button("Retry") { Task { await store.loadProducts() } }
                        .buttonStyle(.bordered)
                        .tint(.purple)
                }
            } else {
                ForEach(store.products, id: \.id) { product in
                    PricingCard(
                        product: product,
                        isPopular: product.id.contains("yearly"),
                        isPurchasing: store.isPurchasing,
                        onPurchase: { purchaseProduct(product) }
                    )
                }
            }

            // Restore
            Button("Restore Purchases") {
                Task { await store.restorePurchases() }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    // MARK: - Legal

    private var legalSection: some View {
        VStack(spacing: 6) {
            Text("Payment will be charged to your Apple ID account. Subscriptions automatically renew unless canceled at least 24 hours before the end of the current period.")
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)

            HStack(spacing: 16) {
                Link("Terms of Use", destination: URL(string: "https://jasonyeyuhe.github.io/Kinen/")!)
                Link("Privacy Policy", destination: URL(string: "https://jasonyeyuhe.github.io/Kinen/")!)
            }
            .font(.system(size: 10))
        }
    }

    private func purchaseProduct(_ product: Product) {
        Task {
            do {
                let success = try await store.purchase(product)
                if success { dismiss() }
            } catch {
                purchaseError = error.localizedDescription
            }
        }
    }
}

// MARK: - Components

struct ProFeatureRow: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 36, height: 36)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct PricingCard: View {
    let product: Product
    let isPopular: Bool
    let isPurchasing: Bool
    let onPurchase: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(product.displayName)
                            .font(.headline)
                        if isPopular {
                            Text("BEST VALUE")
                                .font(.system(size: 9, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.green)
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                        }
                    }
                    Text(product.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(product.displayPrice)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.purple)
            }

            Button(action: onPurchase) {
                if isPurchasing {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                } else {
                    Text("Subscribe")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(isPopular ? .purple : .secondary)
            .disabled(isPurchasing)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isPopular ? Color.purple : .clear, lineWidth: 2)
        )
    }
}
