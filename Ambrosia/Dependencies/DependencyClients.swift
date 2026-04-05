import Foundation

// MARK: - TCA-Style Dependency Clients
// These are protocol-based clients that follow TCA's DependencyClient pattern
// without requiring the full TCA library. This enables easy mocking for tests.

// MARK: - AI Service Client

/// Client for interacting with the AI service (OpenRouter)
protocol AIServiceClientProtocol: Sendable {
    func generateContent(prompt: String, images: [Data]) async throws -> String
    func generateImage(prompt: String) async throws -> URL?
}

/// Live implementation using OpenRouterService
struct AIServiceClient: AIServiceClientProtocol {
    private let service: any GeminiServiceProtocol

    init() {
        self.service = OpenRouterService()
    }

    func generateContent(prompt: String, images: [Data]) async throws -> String {
        try await service.generateContent(prompt: prompt, images: images, model: .flash)
    }

    func generateImage(prompt: String) async throws -> URL? {
        try await service.generateImage(prompt: prompt, model: OpenRouterModel.geminiFlash.rawValue)
    }
}

// MARK: - Decoder Client

/// Client for decoding menu images
protocol DecoderClientProtocol: Sendable {
    func decode(images: [Data]) async throws -> MenuData
}

struct DecoderClient: DecoderClientProtocol {
    private let agent: DecoderAgent
    
    init() {
        self.agent = DecoderAgent()
    }
    
    func decode(images: [Data]) async throws -> MenuData {
        try await agent.decode(images: images)
    }
}

// MARK: - Chef Client

/// Client for generating food recommendations
protocol ChefClientProtocol: Sendable {
    func recommend(from menu: MenuData, profile: IndividualProfile, research: RestaurantResearchData?) async throws -> SoloRecommendationSet
    func recommendCombo(from menu: MenuData, group: GroupProfile, research: RestaurantResearchData?) async throws -> GroupRecommendationSet
}

struct ChefClient: ChefClientProtocol {
    private let agent: ChefAgent
    
    init() {
        self.agent = ChefAgent()
    }
    
    func recommend(from menu: MenuData, profile: IndividualProfile, research: RestaurantResearchData?) async throws -> SoloRecommendationSet {
        try await agent.recommend(from: menu, profile: profile, research: research)
    }
    
    func recommendCombo(from menu: MenuData, group: GroupProfile, research: RestaurantResearchData?) async throws -> GroupRecommendationSet {
        try await agent.recommendGroupCombo(from: menu, group: group, research: research)
    }
}

// MARK: - Safety Client

/// Client for auditing recommendations for safety
protocol SafetyClientProtocol: Sendable {
    func audit(draft: SoloRecommendationSet, context: MenuData, profile: IndividualProfile) async throws -> SoloRecommendationSet
    func auditCombo(draft: GroupRecommendationSet, context: MenuData, group: GroupProfile) async throws -> GroupRecommendationSet
}

struct SafetyClient: SafetyClientProtocol {
    private let agent: SafetyAgent
    
    init() {
        self.agent = SafetyAgent()
    }
    
    func audit(draft: SoloRecommendationSet, context: MenuData, profile: IndividualProfile) async throws -> SoloRecommendationSet {
        try await agent.audit(draft: draft, context: context, profile: profile)
    }
    
    func auditCombo(draft: GroupRecommendationSet, context: MenuData, group: GroupProfile) async throws -> GroupRecommendationSet {
        try await agent.auditCombo(draft: draft, context: context, group: group)
    }
}

// MARK: - Visualizer Client

/// Client for generating dish visualizations
protocol VisualizerClientProtocol: Sendable {
    func visualize(dishName: String, description: String) async throws -> URL?
}

struct VisualizerClient: VisualizerClientProtocol {
    private let agent: VisualizerAgent
    
    init() {
        self.agent = VisualizerAgent()
    }
    
    func visualize(dishName: String, description: String) async throws -> URL? {
        try await agent.visualize(dishName: dishName, culturalDescription: description)
    }
}

// MARK: - Research Client

/// Client for researching restaurant details
protocol ResearchClientProtocol: Sendable {
    func researchRestaurant(name: String, location: String?) async throws -> RestaurantResearchData
}

struct ResearchClient: ResearchClientProtocol {
    private let agent: ResearchAgentProtocol
    
    init() {
        self.agent = ResearchAgent()
    }
    
    func researchRestaurant(name: String, location: String?) async throws -> RestaurantResearchData {
        try await agent.researchRestaurant(name: name, location: location)
    }
}

// MARK: - Dependency Container

/// Container for all app dependencies - enables easy swapping for tests
final class DependencyContainer: @unchecked Sendable {
    static let shared = DependencyContainer()
    
    let decoder: DecoderClientProtocol
    let chef: ChefClientProtocol
    let safety: SafetyClientProtocol
    let visualizer: VisualizerClientProtocol
    let research: ResearchClientProtocol
    
    init(
        decoder: DecoderClientProtocol = DecoderClient(),
        chef: ChefClientProtocol = ChefClient(),
        safety: SafetyClientProtocol = SafetyClient(),
        visualizer: VisualizerClientProtocol = VisualizerClient(),
        research: ResearchClientProtocol = ResearchClient()
    ) {
        self.decoder = decoder
        self.chef = chef
        self.safety = safety
        self.visualizer = visualizer
        self.research = research
    }
}
