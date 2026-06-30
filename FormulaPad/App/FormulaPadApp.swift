import SwiftUI

@main
struct FormulaPadApp: App {
    @StateObject private var store = FormulaPadStore()
    @StateObject private var purchaseManager = PurchaseManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(purchaseManager)
                .tint(AppColor.primary)
                .preferredColorScheme(.light)
        }
    }
}

