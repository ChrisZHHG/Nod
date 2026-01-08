import SwiftUI

@main
struct AmbrosiaApp: App {
    // Legacy manager kept for backwards compatibility
    // @StateObject private var legacyManager = AmbrosiaManager()
    
    var body: some Scene {
        WindowGroup {
            // New TCA-style architecture
            AppRootView()
            
            // Legacy entry point (deprecated)
            // ContentView().environmentObject(legacyManager)
        }
    }
}
