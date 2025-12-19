import Foundation
import SwiftUI
import Combine

// MARK: - App State Definition
enum AppState {
    case idle
    case scanning(images: [Data]) // Holding Base64 encoded or raw data
    case decoding(progress: Double)
    case reasoning(stage: String)
    case verifying
    case result(MenuRecommendation)
    case error(String)
}

// MARK: - Data Models (Placeholders)
struct MenuRecommendation: Codable, Identifiable {
    var id = UUID()
    let dishNameOriginal: String
    let dishNameTranslated: String
    let price: String
    let reasoning: String
    let confidenceScore: Int
}

struct UserProfile {
    var partySize: Int = 2
    var budget: Int = 100
    var allergies: [String] = []
    var tastePreference: String = "Spicy"
}

// MARK: - The Conductor
@MainActor
class AmbrosiaManager: ObservableObject {
    @Published var state: AppState = .idle
    @Published var timelineLog: [String] = [] // For debug/demo UI
    
    // Services
    // Services
    private let decoderAgent: DecoderAgent
    private let cultureAgent: CultureAgent
    private let safetyAgent: SafetyAgent
    private let visualizerAgent: VisualizerAgent
    
    // Data
    private var currentImages: [Data] = []
    var userProfile: UserProfile = UserProfile()
    
    init(service: GeminiServiceProtocol = GeminiService()) {
        self.decoderAgent = DecoderAgent(service: service)
        self.cultureAgent = CultureAgent(service: service)
        self.safetyAgent = SafetyAgent(service: service)
        self.visualizerAgent = VisualizerAgent(service: service)
    }
    
    // MARK: - Public Intents
    
    func startSession() {
        self.state = .scanning(images: [])
        log("👨‍✈️ Session Started. Camera Ready.")
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
            // Step 1: Decode (The Eye)
            self.state = .decoding(progress: 0.2)
            log("👀 Decoder Agent: Scanning Menu Structure...")
            let menuData = try await decoderAgent.decode(images: currentImages)
            self.state = .decoding(progress: 1.0)
            log("✅ Decoder Agent: Found \(menuData.items.count) items.")
            
            // Step 2: Reason (The Brain)
            self.state = .reasoning(stage: "Injecting Bely Persona...")
            log("🧠 Culture Agent: Analyzing with Profile: \(userProfile.tastePreference)")
            var draft = try await cultureAgent.recommend(from: menuData, profile: userProfile)
            
            // Step 2.5: Visualize (The Artist)
            // Fire and forget logic or await? Await for now to ensure result has image.
            log("🎨 Visualizer Agent: Dreaming up the dish...")
            if let imageURL = try? await visualizerAgent.visualize(dishName: draft.translation.localizedName, culturalDescription: draft.translation.culturalContext) {
                draft.imageURL = imageURL
                log("✨ Image Generated.")
            }
            
            // Step 3: Verify (The Critic)
            self.state = .verifying
            log("🛡️ Safety Agent: Checking against allergies: \(userProfile.allergies)")
            let verifiedResult = try await safetyAgent.audit(draft: draft, context: menuData, profile: userProfile)
            
            // Success
            self.state = .result(verifiedResult)
            log("🎉 Recommendation Ready: \(verifiedResult.dishNameTranslated)")
            
        } catch {
            self.state = .error(error.localizedDescription)
            log("❌ Error: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Internal Helper
    private func log(_ message: String) {
        print("[AmbrosiaManager] \(message)")
        timelineLog.append(message)
    }
}

// MARK: - End of File
