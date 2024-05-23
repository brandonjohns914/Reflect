//
//  DataController-StoreKit.swift
//  Journal
//
//  Created by Brandon Johns on 4/5/24.
//

import Foundation
import StoreKit




extension DataController {
    /// The product ID for premium unlock
    
    static let unlockPremiumProductID = "BJ914.Journal"
 
    /// Loads and saves whether our premium unlock has been purchased.
    var fullVersionUnlocked: Bool {
        get {
            defaults.bool(forKey: "fullVersionUnlocked")
        }

        set {
            defaults.set(newValue, forKey: "fullVersionUnlocked")
        }
    }
    
    /// Changing a Published property and dont want to do this on background task
    /// checks the product id and sends a change
    /// revoaction has a date means it was refunded
    @MainActor
    func finalize(_ transaction: Transaction) async {
        if transaction.productID == Self.unlockPremiumProductID {
            objectWillChange.send()
            fullVersionUnlocked = transaction.revocationDate == nil
            await transaction.finish()
        }
    }
    
    func monitorTransactions() async {
        // Check for previous purchases.
        for await entitlement in Transaction.currentEntitlements {
            if case let .verified(transaction) = entitlement {
                await finalize(transaction)
            }
        }

        // Watch for future transactions coming in.
        for await update in Transaction.updates {
            if let transaction = try? update.payloadValue {
                await finalize(transaction)
            }
        }
    }
    

    
    @MainActor
    func loadProducts() async throws {
        // don't load products more than once
        guard products.isEmpty else { return }

        try await Task.sleep(for: .seconds(0.2))
        products = try await Product.products(for: [Self.unlockPremiumProductID])
    }
    
    
}
