import Foundation

// MARK: - TCA-Style Dependency Clients
// These are protocol-based clients that follow TCA's DependencyClient pattern
// without requiring the full TCA library. This enables easy mocking for tests.

// MARK: - Gemini Client

/// Client for interacting with Gemini AI service
protocol GeminiClientProtocol: Sendable {
    func generateContent(prompt: String, images: [Data]) async throws -> String
    func generateImage(prompt: String) async throws -> URL?
}

/// Live implementation using GeminiService actor
struct GeminiClient: GeminiClientProtocol {
    private let service: GeminiService
    
    init() {
        self.service = GeminiService()
    }
    
    func generateContent(prompt: String, images: [Data]) async throws -> String {
        try await service.generateContent(prompt: prompt, images: images, model: .flash)
    }
    
    func generateImage(prompt: String) async throws -> URL? {
        try await service.generateImage(prompt: prompt, model: "imagen-3.0-fast-generate-001")
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
    func recommend(from menu: MenuData, profile: IndividualProfile) async throws -> MenuRecommendation
    func recommendCombo(from menu: MenuData, group: GroupProfile) async throws -> ComboRecommendation
}

struct ChefClient: ChefClientProtocol {
    private let agent: ChefAgent
    
    init() {
        self.agent = ChefAgent()
    }
    
    func recommend(from menu: MenuData, profile: IndividualProfile) async throws -> MenuRecommendation {
        try await agent.recommend(from: menu, profile: profile)
    }
    
    func recommendCombo(from menu: MenuData, group: GroupProfile) async throws -> ComboRecommendation {
        try await agent.recommendGroupCombo(from: menu, group: group)
    }
}

// MARK: - Safety Client

/// Client for auditing recommendations for safety
protocol SafetyClientProtocol: Sendable {
    func audit(draft: MenuRecommendation, context: MenuData, profile: IndividualProfile) async throws -> MenuRecommendation
}

struct SafetyClient: SafetyClientProtocol {
    private let agent: SafetyAgent
    
    init() {
        self.agent = SafetyAgent()
    }
    
    func audit(draft: MenuRecommendation, context: MenuData, profile: IndividualProfile) async throws -> MenuRecommendation {
        try await agent.audit(draft: draft, context: context, profile: profile)
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

// MARK: - Dependency Container

/// Container for all app dependencies - enables easy swapping for tests
final class DependencyContainer: @unchecked Sendable {
    static let shared = DependencyContainer()
    
    let decoder: DecoderClientProtocol
    let chef: ChefClientProtocol
    let safety: SafetyClientProtocol
    let visualizer: VisualizerClientProtocol
    
    init(
        decoder: DecoderClientProtocol = DecoderClient(),
        chef: ChefClientProtocol = ChefClient(),
        safety: SafetyClientProtocol = SafetyClient(),
        visualizer: VisualizerClientProtocol = VisualizerClient()
    ) {
        self.decoder = decoder
        self.chef = chef
        self.safety = safety
        self.visualizer = visualizer
    }
}
