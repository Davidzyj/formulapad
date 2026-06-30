import Foundation
import StoreKit

@MainActor
final class PurchaseManager: ObservableObject {
    static let proProductID = "com.zhouyajie.formulapad.pro"

    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedProductIDs: Set<String> = []
    @Published var purchaseMessage: String?
    @Published var isLoading = false

    private var updates: Task<Void, Never>?

    init() {
        updates = observeTransactionUpdates()
        Task {
            await loadProducts()
            await refreshEntitlements()
        }
    }

    deinit {
        updates?.cancel()
    }

    var isPro: Bool {
        if ScreenshotSupport.isEnabled {
            return true
        }
        return purchasedProductIDs.contains(Self.proProductID)
    }

    var proProduct: Product? {
        products.first { $0.id == Self.proProductID }
    }

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        do {
            products = try await Product.products(for: [Self.proProductID])
        } catch {
            purchaseMessage = error.localizedDescription
        }
    }

    func purchasePro() async {
        if products.isEmpty {
            await loadProducts()
        }
        guard let product = proProduct else {
            purchaseMessage = "Product unavailable"
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await refreshEntitlements()
                await transaction.finish()
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            purchaseMessage = error.localizedDescription
        }
    }

    func restore() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await AppStore.sync()
            await refreshEntitlements()
        } catch {
            purchaseMessage = error.localizedDescription
        }
    }

    func refreshEntitlements() async {
        var ids = Set<String>()
        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result), transaction.productType == .nonConsumable {
                ids.insert(transaction.productID)
            }
        }
        purchasedProductIDs = ids
    }

    private func observeTransactionUpdates() -> Task<Void, Never> {
        Task { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }
                if let transaction = try? self.checkVerified(result) {
                    await self.refreshEntitlements()
                    await transaction.finish()
                }
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let signedType):
            return signedType
        }
    }

    enum StoreError: Error {
        case failedVerification
    }
}
