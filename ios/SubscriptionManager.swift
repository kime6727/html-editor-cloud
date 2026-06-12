import Foundation
import SwiftUI
import StoreKit

@MainActor
class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()
    
    @AppStorage("isProUser") var isPro: Bool = false
    @Published var showPaywall = false
    @Published var products: [Product] = []
    @Published var isPurchasing = false
    @Published var isFetching = false
    
    @AppStorage("publishedCount") var publishedCount: Int = 0
    @AppStorage("publishCountResetDate") var publishCountResetDate: String = ""
    let freeProjectLimit = AppConfig.freeProjectLimit
    let freePublishLimit = AppConfig.freePublishLimit
    let productID = AppConfig.productID
    
    private var updates: Task<Void, Never>?
    
    private init() {
        // Delay StoreKit initialization to avoid blocking startup
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s delay
            await setupStoreKit()
        }
        
        // Check and reset monthly publish count if needed
        checkMonthlyReset()

        // Verify Pro status from StoreKit on startup
        Task {
            _ = await verifyProStatus()
        }
    }
    
    private func checkMonthlyReset() {
        let calendar = Calendar.current
        let now = Date()
        let currentMonth = calendar.component(.month, from: now)
        let currentYear = calendar.component(.year, from: now)
        let expectedResetKey = "\(currentYear)-\(currentMonth)"

        if publishCountResetDate != expectedResetKey {
            publishedCount = 0
            publishCountResetDate = expectedResetKey
        }
    }

    /// Verify Pro status from StoreKit (source of truth) rather than cached UserDefaults
    func verifyProStatus() async -> Bool {
        var foundEntitlement = false
        for await result in StoreKit.Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.productID == productID {
                    foundEntitlement = true
                    break
                }
            }
        }

        // Update cached value to match StoreKit truth
        if isPro != foundEntitlement {
            isPro = foundEntitlement
            if isPro {
                await syncUserProStatus()
            }
        }

        return foundEntitlement
    }
    
    private func setupStoreKit() async {
        updates = Task { [weak self] in
            for await result in StoreKit.Transaction.updates {
                await self?.handleTransaction(result)
            }
        }
        
        await fetchProducts()
        await updateSubscriptionStatus()
    }
    
    func fetchProducts() async {
        isFetching = true
        defer { isFetching = false }
        
        do {
            self.products = try await Product.products(for: [productID])
        } catch {
        }
    }
    
    func canCreateProject(currentCount: Int) -> Bool {
        if isPro { return true }
        return currentCount < freeProjectLimit
    }
    
    func canPublish() -> Bool {
        if isPro { return true }
        checkMonthlyReset()
        return publishedCount < freePublishLimit
    }
    
    func incrementPublishedCount() {
        if !isPro {
            publishedCount += 1
        }
    }
    
    func upgradeToPro() async -> Bool {
        guard let product = products.first(where: { $0.id == productID }) else {
            return false
        }
        
        isPurchasing = true
        defer { isPurchasing = false }
        
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                await handleTransaction(verification)
                showPaywall = false
                return isPro
            case .userCancelled:
                return false
            case .pending:
                return false
            @unknown default:
                return false
            }
        } catch {
            return false
        }
    }
    
    func restorePurchases() async -> Bool {
        do {
            try await AppStore.sync()
            await updateSubscriptionStatus()
            return isPro
        } catch {
            return false
        }
    }
    
    private func handleTransaction(_ result: VerificationResult<StoreKit.Transaction>) async {
        switch result {
        case .verified(let transaction):
            isPro = true
            await transaction.finish()
            await syncUserProStatus()
        case .unverified(let transaction, _):
            if transaction.productID == productID {
                isPro = false
                Task { await syncUserProStatus() }
            }
        }
    }
    
    private func updateSubscriptionStatus() async {
        var foundEntitlement = false
        for await result in StoreKit.Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.productID == productID {
                    foundEntitlement = true
                    break
                }
            }
        }
        isPro = foundEntitlement
        if isPro {
            await syncUserProStatus()
        }
    }
    
    func syncUserProStatus() async {
        guard let url = URL(string: AppConfig.apiBaseURL + "/sync_user.php") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        HMACAuth.applyHeaders(to: &request)

        let body: [String: Any] = [
            "user_id": UserManager.shared.userId,
            "is_pro": isPro
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                print("[SubscriptionManager] Pro status synced to server successfully")
            } else {
                print("[SubscriptionManager] Pro status sync failed with status: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
            }
        } catch {
            print("[SubscriptionManager] Pro status sync network error: \(error.localizedDescription)")
        }
    }
    
    deinit {
        updates?.cancel()
    }
}
