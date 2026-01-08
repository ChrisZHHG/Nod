import Foundation

// MARK: - Agent Protocols for Dependency Injection

protocol DecoderAgentProtocol: Sendable {
    func decode(images: [Data]) async throws -> MenuData
}

protocol ChefAgentProtocol: Sendable {
    func recommend(from menu: MenuData, profile: IndividualProfile) async throws -> MenuRecommendation
    func recommendGroupCombo(from menu: MenuData, group: GroupProfile) async throws -> ComboRecommendation
}

protocol SafetyAgentProtocol: Sendable {
    func audit(draft: MenuRecommendation, context: MenuData, profile: IndividualProfile) async throws -> MenuRecommendation
}

protocol VisualizerAgentProtocol: Sendable {
    func visualize(dishName: String, culturalDescription: String) async throws -> URL?
}
