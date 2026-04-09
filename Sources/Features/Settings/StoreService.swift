import Foundation
import StoreKit
import OSLog

private let logger = Logger(subsystem: "com.jasonye.kinen", category: "Store")

/// StoreKit 2 subscription service. Pattern from Stride (production-tested).
@Observable
@MainActor
final class StoreService {
    static let shared = StoreService()

    enum KinenProduct: String, CaseIterable {
        case monthly = "com.jasonye.kinen.pro.monthly"
        case yearly = "com.jasonye.kinen.pro.yearly"
        case lifetime = "com.jasonye.kinen.pro.lifetime"
    }

    var products: [Product] = []
    var purchasedProductIDs: Set<String> = []
    var isLoading = false
    var loadError: String?
    var isPurchasing = false
    private var loadAttempts = 0
    private var transactionListener: Task<Void, Never>?

    var isPro: Bool { !purchasedProductIDs.isEmpty }

    private init() {
        startTransactionListener()
        Task { await loadProducts() }
        Task { await refreshPurchasedProducts() }
    }

    // MARK: - Load Products

    func loadProducts() async {
        guard !isLoading else { return }
        isLoading = true
        loadError = nil

        do {
            let ids = KinenProduct.allCases.map(\.rawValue)
            products = try await Product.products(for: ids).sorted { $0.price < $1.price }
            loadError = nil
            loadAttempts = 0
            logger.info("Loaded \(self.products.count) products")
        } catch is CancellationError {
            // Don't retry on cancellation
        } catch {
            loadAttempts += 1
            loadError = error.localizedDescription
            logger.error("Failed to load products (attempt \(self.loadAttempts)): \(error)")

            // Exponential backoff retry (max 5 attempts)
            if loadAttempts < 5 {
                let delay = pow(2.0, Double(loadAttempts))
                try? await Task.sleep(for: .seconds(delay))
                await loadProducts()
            }
        }

        isLoading = false
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async throws -> Bool {
        isPurchasing = true
        defer { isPurchasing = false }

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            if let transaction = checkVerified(verification) {
                await transaction.finish()
                await refreshPurchasedProducts()
                logger.info("Purchase successful: \(product.id)")
                return true
            }
            return false
        case .userCancelled:
            return false
        case .pending:
            return false
        @unknown default:
            return false
        }
    }

    // MARK: - Restore

    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await refreshPurchasedProducts()
            logger.info("Purchases restored")
        } catch {
            logger.error("Restore failed: \(error)")
        }
    }

    // MARK: - Transaction Verification

    private func checkVerified<T>(_ result: VerificationResult<T>) -> T? {
        switch result {
        case .verified(let safe): return safe
        case .unverified: return nil
        }
    }

    // MARK: - Refresh Entitlements

    func refreshPurchasedProducts() async {
        var purchased: Set<String> = []
        for await result in Transaction.currentEntitlements {
            if let transaction = checkVerified(result) {
                purchased.insert(transaction.productID)
            }
        }
        purchasedProductIDs = purchased
    }

    // MARK: - Transaction Listener

    private func startTransactionListener() {
        transactionListener = Task.detached {
            for await result in Transaction.updates {
                if let transaction = await self.checkVerified(result) {
                    await transaction.finish()
                    await self.refreshPurchasedProducts()
                }
            }
        }
    }
}
