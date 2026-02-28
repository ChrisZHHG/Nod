import Foundation

/// Defines the contract for external research (e.g., Google Places API)
protocol ResearchAgentProtocol: Sendable {
    /// In the future, this will hit Google Places to fetch reviews and specialties
    func researchRestaurant(name: String, location: String?) async throws -> RestaurantResearchData
}

struct RestaurantResearchData: Codable, Hashable, Sendable {
    let popularDishes: [String]
    let generalVibe: String
    let rating: Double?
}

/// A stubbed implementation that will eventually connect to Real APIs
final class ResearchAgent: ResearchAgentProtocol {
    func researchRestaurant(name: String, location: String?) async throws -> RestaurantResearchData {
        // TODO: Implement Google Places API integration here
        // For Phase 3, this is a placeholder to ensure the architecture is ready.
        return RestaurantResearchData(
            popularDishes: [],
            generalVibe: "Unknown",
            rating: nil
        )
    }
}
