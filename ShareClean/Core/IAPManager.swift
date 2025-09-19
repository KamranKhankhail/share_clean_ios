import Foundation
import StoreKit

final class IAPManager: ObservableObject {
    static let shared = IAPManager()
    let productIDs = ["com.yourcompany.shareclean.lifetime","com.yourcompany.shareclean.monthly"]
    func isProUnlocked() -> Bool { AppConstants.defaults().bool(forKey: "isPro") }
    @MainActor
    func updateEntitlements() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let t) = result {
                if t.productID.contains("lifetime") || t.productType == .autoRenewable {
                    AppConstants.defaults().set(true, forKey: "isPro"); return
                }
            }
        }
        AppConstants.defaults().set(false, forKey: "isPro")
    }
}
