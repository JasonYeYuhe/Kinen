import XCTest
@testable import Kinen

/// Tests for the testable parts of StoreService:
/// KinenProduct enum pure properties and the isPro computed property.
/// Actual StoreKit calls (Product.products, Transaction.*) require a
/// real StoreKit configuration and are tested manually.
@MainActor
final class StoreServiceTests: XCTestCase {

    // MARK: - KinenProduct enum

    func testKinenProductAllCasesCount() {
        XCTAssertEqual(StoreService.KinenProduct.allCases.count, 3)
    }

    func testKinenProductMonthlyRawValue() {
        XCTAssertEqual(StoreService.KinenProduct.monthly.rawValue, "com.jasonye.kinen.pro.monthly")
    }

    func testKinenProductYearlyRawValue() {
        XCTAssertEqual(StoreService.KinenProduct.yearly.rawValue, "com.jasonye.kinen.pro.yearly")
    }

    func testKinenProductLifetimeRawValue() {
        XCTAssertEqual(StoreService.KinenProduct.lifetime.rawValue, "com.jasonye.kinen.pro.lifetime")
    }

    func testKinenProductRawValuesAreDistinct() {
        let ids = StoreService.KinenProduct.allCases.map(\.rawValue)
        XCTAssertEqual(Set(ids).count, ids.count, "All product IDs must be unique")
    }

    // MARK: - isPro

    func testIsProFalseWhenPurchasedProductIDsEmpty() {
        let service = StoreService.shared
        let prior = service.purchasedProductIDs
        defer { service.purchasedProductIDs = prior }

        service.purchasedProductIDs = []
        XCTAssertFalse(service.isPro, "isPro must be false when purchasedProductIDs is empty")
    }

    func testIsProTrueWhenPurchasedProductIDsNonEmpty() {
        let service = StoreService.shared
        let prior = service.purchasedProductIDs
        defer { service.purchasedProductIDs = prior }

        service.purchasedProductIDs = [StoreService.KinenProduct.monthly.rawValue]
        XCTAssertTrue(service.isPro, "isPro must be true when purchasedProductIDs is non-empty")
    }
}
