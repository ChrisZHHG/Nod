import SwiftUI

@main
struct NodApp: App {

    init() {
        // Prefetch API keys from remote config in the background
        // so the first AI call doesn't need to wait for the network round-trip.
        APIKeyService.shared.prefetch()
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
        }
    }
}
