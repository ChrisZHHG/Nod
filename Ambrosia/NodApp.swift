import SwiftUI

@main
struct NodApp: App {
    
    var body: some Scene {
        WindowGroup {
            // New TCA-style architecture
            AppRootView()
            
            // Legacy entry point (deprecated)
            // ContentView().environmentObject(legacyManager)
        }
    }
}
