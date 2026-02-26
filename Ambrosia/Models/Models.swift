import Foundation

// MARK: - Core App State Models

enum AppMode: String, Codable, Equatable, Sendable {
    case individual
    case group
}

enum AppState: Equatable, Sendable {
    case idle
    case scanning
    case decoding(progress: Double)
    case reasoning(stage: String)
    case verifying
    case error(String)
}

// MARK: - Core Data Models (Schema.org compliant)

/// Represents the top-level structure of a recognized menu
struct MenuData: Codable, Hashable, Sendable {
    let sections: [MenuSection]
    let currency: String
    let languageDetected: String
    let metadata: MenuMetadata
    
    // Helper to flatten items for counting
    var totalItems: Int {
        sections.reduce(0) { $0 + $1.items.count }
    }
}

struct MenuMetadata: Codable, Hashable, Sendable {
    let restaurantName: String?
    let timestamp: String
    /// Cuisine style auto-detected by DecoderAgent from the menu image
    /// e.g. "Chinese", "Japanese", "Italian", "Hotpot", "Fusion"
    var cuisineStyle: String?
}


/// Represents a physical section on the menu (e.g., "Starters", "Mains")
struct MenuSection: Codable, Identifiable, Hashable, Sendable {
    var id: String { name }
    let name: String
    let items: [MenuItem]
}

/// A specific dish or drink
struct MenuItem: Codable, Identifiable, Hashable, Sendable {
    var id: String { originalName }
    
    let originalName: String
    let description: String?
    let price: Double?
    
    // AI-Inferred Attributes (Optional to reflect "Unknown" state)
    var isSpicy: Bool? = nil
    var isVegetarian: Bool? = nil
    var containsGluten: Bool? = nil
    var containsPeanuts: Bool? = nil
    var containsSeafood: Bool? = nil
    
    // For V2: Recommendation Score
    var matchScore: Double? = nil
}

// MARK: - Recommendation Models

/// Simplified item returned by ChefAgent (doesn't need all MenuItem fields)
struct RecommendedItem: Codable, Hashable, Sendable {
    let originalName: String
    let description: String?
    let price: Double?
}

struct MenuRecommendation: Codable, Identifiable, Hashable, Sendable {
    var id = UUID()
    let recommendedItem: RecommendedItem  // Changed from MenuItem
    let translation: CulturalTranslation
    let reasoning: String
    let pairings: [Pairing]?
    var imageURL: URL? = nil
    
    enum CodingKeys: String, CodingKey {
        case recommendedItem, translation, reasoning, pairings, imageURL
    }
}

struct Pairing: Codable, Hashable, Sendable {
    let originalName: String
    let reason: String
}

struct CulturalTranslation: Codable, Hashable, Sendable {
    let localizedName: String
    let culturalContext: String
    let warnings: [String]

}

// MARK: - V2: Individual Profile
struct IndividualProfile: Codable, Hashable, Sendable {
    var partySize: Int = 1
    var budget: Int = 50
    var allergies: [String] = []
    var tastePreference: String = "Spicy" // "Authentic", "Mild"
}

// MARK: - V2 Group Models

struct GroupProfile: Codable, Hashable, Sendable {
    var headcount: Int = 4
    var budgetTotal: Int = 200
    var dietaryRestrictions: [String] = [] // "No Pork", "Vegetarian"
    var collectiveAllergies: [String] = [] // "Peanuts"
    var refinementKeywords: [String] = []  // "Seafood", "Fried" (The "Something Else" input)
}

struct ComboRecommendation: Codable, Identifiable, Hashable, Sendable {
    var id = UUID()
    let name: String
    let dishes: [RecommendedItem]  // Changed from MenuItem
    let drinks: [DrinkRecommendation]
    let totalPrice: Double
    let reasoning: String
    var imageURL: URL? = nil
    
    enum CodingKeys: String, CodingKey {
        case name, dishes, drinks, totalPrice, reasoning, imageURL
    }
}

struct DrinkRecommendation: Codable, Identifiable, Hashable, Sendable {
    var id: String { name }
    let name: String
    let type: String // "Alcoholic", "Zero-Proof"
    let description: String
    let pairingReason: String
}

// MARK: - Temp UserProfile for SafetyAgent
// Obsolete UserProfile removed to avoid confusion with IndividualProfile
