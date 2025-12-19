import Foundation
import SwiftUI
import Combine

// MARK: - App State Definition
// MARK: - App State Definition

enum AppMode {
    case individual
    case group
}

enum AppState: Equatable {
    case idle
    case scanning(images: [Data])
    case decoding(progress: Double)
    case reasoning(stage: String)
    case verifying
    case result(MenuRecommendation)      // Individual Result
    case resultCombo(ComboRecommendation) // Group Result
    case error(String)
    
    static func == (lhs: AppState, rhs: AppState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle): return true
        case (.verifying, .verifying): return true
        case (.scanning(let l), .scanning(let r)): return l.count == r.count
        case (.decoding(let l), .decoding(let r)): return l == r
        case (.reasoning(let l), .reasoning(let r)): return l == r
        case (.result(let l), .result(let r)): return l.id == r.id
        case (.resultCombo(let l), .resultCombo(let r)): return l.id == r.id
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
    
    // Services
    private let decoderAgent: DecoderAgent
    private let chefAgent: ChefAgent
    private let safetyAgent: SafetyAgent
    private let visualizerAgent: VisualizerAgent
    
    // Data
    private var currentImages: [Data] = []
    
    init(service: GeminiServiceProtocol = GeminiService()) {
        self.decoderAgent = DecoderAgent(service: service)
        self.chefAgent = ChefAgent(service: service)
        self.safetyAgent = SafetyAgent(service: service)
        self.visualizerAgent = VisualizerAgent(service: service)
    }
    
    // MARK: - Use Cases
    
    func setMode(_ mode: AppMode) {
        self.appMode = mode
        self.state = .idle
        currentImages = []
        log("🔄 Switched to \(mode) mode.")
    }
    
    func startSession() {
        self.state = .scanning(images: [])
        log("👨‍✈️ Session Started (\(appMode)).")
    }
    
    func addImage(_ imageData: Data) {
        if case .scanning(let existing) = state {
            currentImages = existing + [imageData]
            self.state = .scanning(images: currentImages)
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
            log("✅ Found \(menuData.items.count) items.")
            
            // Step 2: Fork based on Mode
            if appMode == .individual {
                try await handleIndividualflow(using: menuData)
            } else {
                try await handleGroupFlow(using: menuData)
            }
            
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
        
        self.state = .result(verifiedResult)
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

        self.state = .resultCombo(combo)
        log("🎉 Group Feast Ready.")
    }
    
    // MARK: - Internal Helper
    private func log(_ message: String) {
        print("[AmbrosiaManager] \(message)")
        timelineLog.append(message)
    }
}

// MARK: - End of File
