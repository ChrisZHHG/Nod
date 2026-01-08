import Foundation
import SwiftUI
import Combine

// MARK: - App State Definition

enum AppMode {
    case individual
    case group
}

enum AppState: Equatable {
    case idle
    case scanning
    case decoding(progress: Double)
    case reasoning(stage: String)
    case verifying
    case error(String)
    
    static func == (lhs: AppState, rhs: AppState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle): return true
        case (.scanning, .scanning): return true
        case (.verifying, .verifying): return true
        case (.decoding(let l), .decoding(let r)): return l == r
        case (.reasoning(let l), .reasoning(let r)): return l == r
        case (.error(let l), .error(let r)): return l == r
        default: return false
        }
    }
}

// MARK: - The Conductor
@MainActor
class AmbrosiaManager: ObservableObject {
    @Published var state: AppState = .idle
    @Published var timelineLog: [String] = []
    
    // V2: Mode Selection
    @Published var appMode: AppMode = .individual
    
    // Data Profiles
    @Published var individualProfile: IndividualProfile = IndividualProfile()
    @Published var groupProfile: GroupProfile = GroupProfile()
    
    // Navigation
    @Published var path = NavigationPath()
    
    enum Destination: Hashable {
        case scanner
        case result(MenuRecommendation)
        case combo(ComboRecommendation)
    }
    
    // Services
    // Services (Protocol-based DI)
    private let decoderAgent: DecoderAgentProtocol
    private let chefAgent: ChefAgentProtocol
    private let safetyAgent: SafetyAgentProtocol
    private let visualizerAgent: VisualizerAgentProtocol
    
    // Data
    @Published private(set) var currentImages: [Data] = []
    
    init(
        service: GeminiServiceProtocol = GeminiService(),
        decoder: DecoderAgentProtocol? = nil,
        chef: ChefAgentProtocol? = nil,
        safety: SafetyAgentProtocol? = nil,
        visualizer: VisualizerAgentProtocol? = nil
    ) {
        // If specific agents are passed (e.g. Mocks), use them.
        // Otherwise, instantiate real agents with the provided (or default) service.
        self.decoderAgent = decoder ?? DecoderAgent(service: service)
        self.chefAgent = chef ?? ChefAgent(service: service)
        self.safetyAgent = safety ?? SafetyAgent(service: service)
        self.visualizerAgent = visualizer ?? VisualizerAgent(service: service)
    }
    
    // MARK: - Use Cases
    
    func setMode(_ mode: AppMode) {
        self.appMode = mode
        self.state = .idle
        currentImages = []
        log("🔄 Switched to \(mode) mode.")
    }
    
    func startSession() {
        self.state = .scanning
        path.append(Destination.scanner)
        log("👨‍✈️ Session Started (\(appMode)).")
    }
    
    func resetSession() {
        self.state = .idle
        self.path = NavigationPath()
        self.currentImages = []
        log("🔄 Session Reset.")
    }
    
    func addImage(_ imageData: Data) {
        if state == .scanning {
            // Debounce/Deduplicate: Ignore if exact same image added < 1s ago
            if let last = currentImages.last, last.count == imageData.count {
                print("[AmbrosiaManager] ⚠️ Duplicate image ignored.")
                return 
            }
            
            currentImages.append(imageData)
            log("📸 Image Captured. Total: \(currentImages.count)")
        }
    }
    
    func generateRecommendation() async {
        guard !currentImages.isEmpty else {
            self.state = .error("No images captured")
            return
        }
        
        do {
            // Step 1: Decode (Common for both modes)
            self.state = .decoding(progress: 0.2)
            log("👀 Decoder Agent: Scanning Menu...")
            let menuData = try await decoderAgent.decode(images: currentImages)
            // log("✅ Found \(menuData.totalItems) items.")
            
            // Step 2: Fork based on Mode
            if appMode == .individual {
                try await handleIndividualflow(using: menuData)
            } else {
                try await handleGroupFlow(using: menuData)
            }
            
            // IMPORTANT: If successful, the path is updated in the handlers. 
            // The State might remain as 'result' or 'combo' to ensure logic consistency, 
            // but the NavigationStack will handle the View transition.
            
        } catch {
            self.state = .error(error.localizedDescription)
            log("❌ Error: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Logic Forks
    
    private func handleIndividualflow(using menuData: MenuData) async throws {
        self.state = .reasoning(stage: "Personalizing for You...")
        var draft = try await chefAgent.recommend(from: menuData, profile: individualProfile)
        
        // Visualizer
        if let imageURL = try? await visualizerAgent.visualize(dishName: draft.translation.localizedName, culturalDescription: draft.translation.culturalContext) {
            draft.imageURL = imageURL
        }
        
        // Safety Audit
        self.state = .verifying
        let verifiedResult = try await safetyAgent.audit(draft: draft, context: menuData, profile: individualProfile)
        
        self.state = .idle // Task done, UI is now driven by NavigationPath
        path.append(Destination.result(verifiedResult))
        log("🎉 Individual Recommendation Ready.")
    }
    
    private func handleGroupFlow(using menuData: MenuData) async throws {
        self.state = .reasoning(stage: "Assembling Group Combo...")
        log("👨‍🍳 Chef Agent: Solving Knapsack for \(groupProfile.headcount) people...")
        
        var combo = try await chefAgent.recommendGroupCombo(from: menuData, group: groupProfile)
        
        // Visualizer (Table Spread)
        if let imageURL = try? await visualizerAgent.visualize(dishName: combo.name, culturalDescription: "A banquet table spread with \(combo.dishes.count) dishes: \(combo.dishes.map{$0.originalName}.joined(separator: ", "))") {
            combo.imageURL = imageURL
        }

        self.state = .idle // Task done
        path.append(Destination.combo(combo))
        log("🎉 Group Feast Ready.")
    }
    
    // MARK: - Internal Helper
    private func log(_ message: String) {
        print("[AmbrosiaManager] \(message)")
        timelineLog.append(message)
    }
}

// MARK: - End of File
