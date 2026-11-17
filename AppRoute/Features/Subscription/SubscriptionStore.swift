import Foundation
import Observation
import StoreKit

@Observable
@MainActor
final class SubscriptionStore {
    var products: [Product] = []
    var purchasedIDs: Set<String> = []
    var loadError: String?
    var isLoading = false

    var isPro: Bool {
        purchasedIDs.isEmpty == false
    }

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        do {
            products = try await Product.products(for: ProductIdentifier.allCases.map(\.rawValue))
                .sorted { lhs, rhs in
                    lhs.id == ProductIdentifier.yearly.rawValue && rhs.id != ProductIdentifier.yearly.rawValue
                }
            loadError = nil
            await refreshEntitlements()
        } catch {
            loadError = error.localizedDescription
        }
    }

    func purchase(_ product: Product) async {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                purchasedIDs.insert(transaction.productID)
                await transaction.finish()
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            loadError = error.localizedDescription
        }
    }

    func restore() async {
        do {
            try await AppStore.sync()
            await refreshEntitlements()
        } catch {
            loadError = error.localizedDescription
        }
    }

    func refreshEntitlements() async {
        var ids: Set<String> = []
        for await entitlement in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(entitlement) {
                ids.insert(transaction.productID)
            }
        }
        purchasedIDs = ids
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw AppRouteError.subscriptionUnavailable("The App Store could not verify the transaction.")
        case .verified(let value):
            value
        }
    }
}
