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
            .navigationTitle(String(localized: "pro.title"))
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "general.done")) { dismiss() }
                }
            }
            .alert(String(localized: "pro.error"), isPresented: .constant(purchaseError != nil)) {
                Button(String(localized: "general.done")) { purchaseError = nil }
            } message: {
                Text(purchaseError ?? "")
            }
        }
        #if os(macOS)
        .frame(minWidth: 420, idealWidth: 500, minHeight: 500, idealHeight: 600)
        #endif
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "crown.fill")
                .font(.system(size: 48))
                .foregroundStyle(.purple.gradient)

            Text(String(localized: "pro.unlock"))
                .font(.title)
                .fontWeight(.bold)

            Text(String(localized: "pro.description"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Features

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            ProFeatureRow(icon: "brain.head.profile", color: .purple, title: String(localized: "pro.feature.ai"), subtitle: String(localized: "pro.feature.ai.desc"))
            ProFeatureRow(icon: "chart.line.uptrend.xyaxis", color: .blue, title: String(localized: "pro.feature.insights"), subtitle: String(localized: "pro.feature.insights.desc"))
            ProFeatureRow(icon: "icloud.fill", color: .cyan, title: String(localized: "pro.feature.sync"), subtitle: String(localized: "pro.feature.sync.desc"))
            ProFeatureRow(icon: "square.and.arrow.up", color: .green, title: String(localized: "pro.feature.export"), subtitle: String(localized: "pro.feature.export.desc"))
            ProFeatureRow(icon: "doc.text", color: .orange, title: String(localized: "pro.feature.templates"), subtitle: String(localized: "pro.feature.templates.desc"))
            ProFeatureRow(icon: "sparkles", color: .pink, title: String(localized: "pro.feature.prompts"), subtitle: String(localized: "pro.feature.prompts.desc"))
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Pricing

    private var pricingSection: some View {
        VStack(spacing: 12) {
            if store.isLoading {
                ProgressView(String(localized: "pro.loading"))
            } else if store.products.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.title2)
                        .foregroundStyle(.orange)
                    Text(String(localized: "pro.loadFailed"))
                        .font(.subheadline)
                    if let error = store.loadError {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Button(String(localized: "pro.retry")) { Task { await store.loadProducts() } }
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
            Button(String(localized: "pro.restore")) {
                Task { await store.restorePurchases() }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    // MARK: - Legal

    private var legalSection: some View {
        VStack(spacing: 6) {
            Text(String(localized: "pro.legal"))
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)

            HStack(spacing: 16) {
                // Apple's Standard End User License Agreement (Schedule 1).
                // Required by Guideline 3.1.2(c) for auto-renewable subscriptions.
                Link(String(localized: "pro.terms"),
                     destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                Link(String(localized: "pro.privacy"),
                     destination: URL(string: "https://jasonyeyuhe.github.io/Kinen/privacy.html")!)
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
                            Text(String(localized: "pro.bestValue"))
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
                    Text(String(localized: "pro.subscribe"))
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
