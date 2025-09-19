import SwiftUI
import StoreKit

struct PaywallView: View {
    @State private var products: [Product] = []
    @EnvironmentObject var app: AppState
    var body: some View {
        VStack(spacing: 16) {
            Text("Go Pro").font(.title2).bold()
            Text("Unlimited auto-redaction, batch mode, priority processing.").font(.subheadline).multilineTextAlignment(.center)
            ForEach(products, id: \.id) { p in
                Button(action: { Task { await buy(p) } }) {
                    Text("\(p.displayName) • \(p.displayPrice)").frame(maxWidth: .infinity).padding().background(Color.black).foregroundColor(.white).cornerRadius(12)
                }
            }
            Spacer()
        }.padding().task { await load() }
    }
    func load() async {
        do {
            let prods = try await Product.products(for: IAPManager.shared.productIDs)
            products = prods
        } catch {
            print("Failed to load products: \(error)")
        }
    }
    func buy(_ p: Product) async {
        do {
            let res = try await p.purchase()
            switch res {
            case .success(let v):
                if case .verified(_) = v {
                    await IAPManager.shared.updateEntitlements()
                    app.isPro = IAPManager.shared.isProUnlocked()
                }
            case .userCancelled:
                print("Purchase cancelled by user")
            case .pending:
                print("Purchase pending")
            @unknown default:
                print("Unknown purchase result")
            }
        } catch {
            print("Purchase failed: \(error)")
        }
    }
}
