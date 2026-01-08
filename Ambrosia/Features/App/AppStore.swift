import Foundation
import SwiftUI

// MARK: - App Domain (State, Action, Effect)

/// Application-wide state following TCA patterns
@Observable
@MainActor
final class AppStore {
    // MARK: - State
    
    var mode: AppMode = .individual
    var appState: AppState = .idle
    var individualProfile: IndividualProfile = .init()
    var groupProfile: GroupProfile = .init()
    var capturedImages: [Data] = []
    var timelineLog: [String] = []
    
    // Navigation (using enum path for type-safe navigation)
    var navigationPath: [AppDestination] = []
    
    // Dependencies
    private let dependencies: DependencyContainer
    
    init(dependencies: DependencyContainer = .shared) {
        self.dependencies = dependencies
    }
    
    // MARK: - Actions (via methods that mirror TCA Action enum)
    
    func setMode(_ mode: AppMode) {
        self.mode = mode
        self.appState = .idle
        self.capturedImages = []
        log("🔄 Switched to \(mode) mode.")
    }
    
    func startSession() {
        self.appState = .scanning
        navigationPath.append(.scanner)
        log("👨‍✈️ Session Started (\(mode)).")
    }
    
    func resetSession() {
        self.appState = .idle
        self.navigationPath = []
        self.capturedImages = []
        log("🔄 Session Reset.")
    }
    
    func captureImage(_ imageData: Data) {
        guard appState == .scanning else { return }
        capturedImages.append(imageData)
        log("📸 Image Captured. Total: \(capturedImages.count)")
    }
    
    // MARK: - Effects (Async Operations)
    
    func generateRecommendation() async {
        guard !capturedImages.isEmpty else {
            self.appState = .error("No images captured")
            return
        }
        
        do {
            // Step 1: Decode
            self.appState = .decoding(progress: 0.2)
            log("👀 Decoder Agent: Scanning Menu...")
            let menuData = try await dependencies.decoder.decode(images: capturedImages)
            
            // Step 2: Fork based on Mode
            if mode == .individual {
                try await handleIndividualFlow(using: menuData)
            } else {
                try await handleGroupFlow(using: menuData)
            }
            
        } catch {
            self.appState = .error(error.localizedDescription)
            log("❌ Error: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Private Effects
    
    private func handleIndividualFlow(using menuData: MenuData) async throws {
        self.appState = .reasoning(stage: "Personalizing for You...")
        log("👨‍🍳 Chef Agent: Crafting recommendation...")
        
        var draft = try await dependencies.chef.recommend(from: menuData, profile: individualProfile)
        
        // Visualizer
        if let imageURL = try? await dependencies.visualizer.visualize(
            dishName: draft.translation.localizedName,
            description: draft.translation.culturalContext
        ) {
            draft.imageURL = imageURL
        }
        
        // Safety Audit
        self.appState = .verifying
        log("🛡️ Safety Agent: Auditing...")
        let verifiedResult = try await dependencies.safety.audit(
            draft: draft,
            context: menuData,
            profile: individualProfile
        )
        
        self.appState = .idle
        navigationPath.append(.result(verifiedResult))
        log("🎉 Individual Recommendation Ready.")
    }
    
    private func handleGroupFlow(using menuData: MenuData) async throws {
        self.appState = .reasoning(stage: "Assembling Group Combo...")
        log("👨‍🍳 Chef Agent: Solving Knapsack for \(groupProfile.headcount) people...")
        
        var combo = try await dependencies.chef.recommendCombo(from: menuData, group: groupProfile)
        
        // Visualizer
        let dishNames = combo.dishes.map { $0.originalName }.joined(separator: ", ")
        if let imageURL = try? await dependencies.visualizer.visualize(
            dishName: combo.name,
            description: "A banquet table spread with \(combo.dishes.count) dishes: \(dishNames)"
        ) {
            combo.imageURL = imageURL
        }
        
        self.appState = .idle
        navigationPath.append(.combo(combo))
        log("🎉 Group Feast Ready.")
    }
    
    // MARK: - Logging
    
    private func log(_ message: String) {
        print("[AppStore] \(message)")
        timelineLog.append(message)
    }
}

// MARK: - Navigation Destination

enum AppDestination: Hashable {
    case scanner
    case result(MenuRecommendation)
    case combo(ComboRecommendation)
}
