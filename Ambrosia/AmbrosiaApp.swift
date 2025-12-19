import SwiftUI

@main
struct AmbrosiaApp: App {
    @StateObject private var manager = AmbrosiaManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(manager)
        }
    }
}
