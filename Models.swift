import Foundation

// MARK: - Core Data Models (Schema.org compliant)

/// Represents the top-level structure of a recognized menu
struct MenuData: Codable, Equatable {
    let sections: [MenuSection]
    let currency: String
    let languageDetected: String
    let metadata: MenuMetadata
    
    // Helper to flatten items for counting
    var totalItems: Int {
        sections.reduce(0) { $0 + $1.items.count }
    }
}

struct MenuMetadata: Codable, Equatable {
    let restaurantName: String?
    let timestamp: Date
}

/// Represents a physical section on the menu (e.g., "Starters", "Mains")
struct MenuSection: Codable, Identifiable, Equatable {
    var id: String { name }
    let name: String
    let items: [MenuItem]
}

/// A specific dish or drink
struct MenuItem: Codable, Identifiable, Equatable {
    var id: String { originalName }
    
    let originalName: String
    let description: String?
    let price: Double?
    
    // AI-Inferred Attributes
    let isSpicy: Bool
    let isVegetarian: Bool
    let containsGluten: Bool
    let containsPeanuts: Bool
    let containsSeafood: Bool
    
    // For V2: Recommendation Score
    var matchScore: Double? = nil
}

// MARK: - Recommendation Models

struct MenuRecommendation: Codable, Identifiable {
    var id = UUID()
    let recommendedItem: MenuItem
    let translation: CulturalTranslation
    let reasoning: String
    let pairings: [String]? // e.g., Wine pairing
}

struct CulturalTranslation: Codable {
    let localizedName: String // "夫妻肺片" -> "Spicy Beef & Tripe"
    let culturalContext: String // "Served cold, numbing spicy, popular appetizer"
    let warnings: [String] // ["Offal", "High Sodium"]
}
