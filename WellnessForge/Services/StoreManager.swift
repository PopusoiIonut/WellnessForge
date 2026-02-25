import StoreKit

class StoreManager: ObservableObject {
    @Published var subscriptions: [Product] = []
    @Published var purchasedSubscriptions: [String] = []
    
    @Published var isLoading: Bool = false
    @Published var fetchError: String? = nil
    
    // Fallback UI mock string if StoreKit is entirely broken by Xcode
    @Published var mockFallbackAvailable: Bool = false
    
    private let productIds = ["wellness_pro_yearly"]
    private var updates: Task<Void, Never>? = nil

    init() {
        updates = listenForTransactions()
        Task {
            await fetchProducts()
            await updatePurchasedProducts()
        }
    }

    deinit {
        updates?.cancel()
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached {
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await self.updatePurchasedProducts()
                    await transaction.finish()
                }
            }
        }
    }

    @MainActor
    func fetchProducts() async {
        isLoading = true
        fetchError = nil
        self.mockFallbackAvailable = false
        
        print("StoreKit: Starting product fetch for: \(productIds)")
        
        do {
            let products = try await Product.products(for: productIds)
            self.subscriptions = products.sorted(by: { $0.price < $1.price })
            
            print("StoreKit: Fetched \(products.count) products.")
            
            if products.isEmpty {
                self.fetchError = "No products found in the store. Check StoreKit configuration."
                print("StoreKit Error: Fetch returned zero products. Ensure .storekit file is active in the scheme.")
                
                #if DEBUG
                // Enable a mock UI fallback for testing when StoreKit refuses to bind properly
                self.mockFallbackAvailable = true
                // Do NOT clear fetchError here, otherwise SubscriptionView bypasses the error state harboring our mock button.
                #endif
            }
        } catch {
            self.fetchError = "Fetch Error: \(error.localizedDescription)"
            print("StoreKit Critical Error: \(error)")
        }
        isLoading = false
    }

    @MainActor
    func updatePurchasedProducts() async {
        var purchased: [String] = []
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.revocationDate == nil {
                    purchased.append(transaction.productID)
                }
            }
        }
        self.purchasedSubscriptions = purchased
    }

    func buy(_ product: Product) async throws {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            if case .verified(let transaction) = verification {
                await updatePurchasedProducts()
                await transaction.finish()
            }
        case .userCancelled, .pending:
            break
        @unknown default:
            break
        }
    }
    
    var isPremium: Bool {
        !purchasedSubscriptions.isEmpty
    }
}
