import Foundation
import StoreKit

/// Manifest Premium aboneliğini yönetir (StoreKit 2).
/// Üç plan: haftalık, aylık, yıllık — hepsinde 3 gün ücretsiz deneme.
@MainActor
final class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()

    /// App Store Connect'teki ürün kimlikleriyle birebir aynı olmalı.
    static let weeklyID  = "manifest_premium_weekly"
    static let monthlyID = "manifest_premium_monthly"
    static let yearlyID  = "manifest_premium_yearly"
    static let allIDs = [weeklyID, monthlyID, yearlyID]

    @Published private(set) var products: [Product] = []
    @Published private(set) var isPremium = false
    @Published var isWorking = false
    @Published var errorMessage: String?

    private var updatesTask: Task<Void, Never>?

    private init() {
        updatesTask = observeTransactionUpdates()
        Task {
            await loadProducts()
            await refreshEntitlements()
        }
    }

    deinit { updatesTask?.cancel() }

    /// Yıllık planın anahtar kimliği (paywall'da "en avantajlı" olarak öne çıkar).
    func product(for id: String) -> Product? {
        products.first { $0.id == id }
    }

    func loadProducts() async {
        do {
            let fetched = try await Product.products(for: Self.allIDs)
            // Haftalık → aylık → yıllık sırasına diz.
            products = fetched.sorted {
                (Self.allIDs.firstIndex(of: $0.id) ?? 0) < (Self.allIDs.firstIndex(of: $1.id) ?? 0)
            }
        } catch {
            products = []
        }
    }

    /// Aktif (iptal/iade edilmemiş) bir abonelik var mı diye bakar.
    func refreshEntitlements() async {
        var active = false
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            if Self.allIDs.contains(transaction.productID),
               transaction.revocationDate == nil {
                active = true
            }
        }
        isPremium = active
        // MainActor dışından (ManifestProvider) okunabilsin diye yansıt.
        UserDefaults.standard.set(active, forKey: "premiumActive")
    }

    func purchase(_ product: Product) async {
        isWorking = true
        errorMessage = nil
        defer { isWorking = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await transaction.finish()
                    await refreshEntitlements()
                }
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// "Satın alımları geri yükle": Apple ile senkron edip yetkileri tazeler.
    func restore() async {
        isWorking = true
        defer { isWorking = false }
        try? await AppStore.sync()
        await refreshEntitlements()
    }

    private func observeTransactionUpdates() -> Task<Void, Never> {
        Task { [weak self] in
            for await result in Transaction.updates {
                guard case .verified(let transaction) = result else { continue }
                await transaction.finish()
                await self?.refreshEntitlements()
            }
        }
    }
}
