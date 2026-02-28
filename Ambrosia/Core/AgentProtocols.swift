import Foundation

// MARK: - Agent Protocols for Dependency Injection

protocol DecoderAgentProtocol: Sendable {
    func decode(images: [Data]) async throws -> MenuData
}

protocol ChefAgentProtocol: Sendable {
    func recommend(from menu: MenuData, profile: IndividualProfile, research: RestaurantResearchData?) async throws -> SoloRecommendationSet
    func recommendGroupCombo(from menu: MenuData, group: GroupProfile, research: RestaurantResearchData?) async throws -> GroupRecommendationSet
}

protocol SafetyAgentProtocol: Sendable {
    func audit(draft: SoloRecommendationSet, context: MenuData, profile: IndividualProfile) async throws -> SoloRecommendationSet
    func auditCombo(draft: GroupRecommendationSet, context: MenuData, group: GroupProfile) async throws -> GroupRecommendationSet
}

protocol VisualizerAgentProtocol: Sendable {
    func visualize(dishName: String, culturalDescription: String) async throws -> URL?
}
