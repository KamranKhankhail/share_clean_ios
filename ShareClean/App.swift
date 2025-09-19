import SwiftUI

@main
struct ShareCleanApp: App {
    @StateObject var appState = AppState()
    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(appState)
        }
    }
}

final class AppState: ObservableObject {
    @Published var isPro: Bool = IAPManager.shared.isProUnlocked()
    @Published var settings: DetectionSettings = DetectionSettings.default
}
