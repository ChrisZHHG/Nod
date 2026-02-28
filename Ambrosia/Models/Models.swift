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

/// Simplified item returned by ChefAgent
struct RecommendedItem: Codable, Hashable, Sendable {
    let originalName: String
    let description: String?
    let price: Double?
    var imageURL: URL? = nil
}

/// A collection of 3 personalized options for a solo diner
struct SoloRecommendationSet: Codable, Hashable, Sendable {
    let options: [MenuRecommendation]
}

/// A single option within the solo recommendation set
struct MenuRecommendation: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let optionType: String // e.g., "The Crowd Pleaser", "Local Secret", "Adventurous"
    let recommendedItem: RecommendedItem
    let translation: CulturalTranslation
    let reasoning: String
    let pairings: [Pairing]?
    let imageURL: URL? // URL strictly comes from Presentation layer or a copy, not a mutation
    
    init(id: UUID = UUID(), optionType: String, recommendedItem: RecommendedItem, translation: CulturalTranslation, reasoning: String, pairings: [Pairing]?, imageURL: URL? = nil) {
        self.id = id
        self.optionType = optionType
        self.recommendedItem = recommendedItem
        self.translation = translation
        self.reasoning = reasoning
        self.pairings = pairings
        self.imageURL = imageURL
    }
    
    enum CodingKeys: String, CodingKey {
        case optionType, recommendedItem, translation, reasoning, pairings, imageURL
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.optionType = try container.decode(String.self, forKey: .optionType)
        self.recommendedItem = try container.decode(RecommendedItem.self, forKey: .recommendedItem)
        self.translation = try container.decode(CulturalTranslation.self, forKey: .translation)
        self.reasoning = try container.decode(String.self, forKey: .reasoning)
        self.pairings = try container.decodeIfPresent([Pairing].self, forKey: .pairings)
        self.imageURL = try container.decodeIfPresent(URL.self, forKey: .imageURL)
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

// MARK: - Progressive Profiles

/// Profile for Individual Mode
struct IndividualProfile: Codable, Hashable, Sendable {
    var partySize: Int = 1
    var vetoes: [String] = []       // e.g., "Pork", "Peanuts", "Cilantro"
    var cravings: [String] = []     // e.g., "Heavy", "Fresh", "Something Else..."
    var mood: String = "Relaxed"    // Environmental context
}

/// Profile for Group Mode (Sharing)
struct GroupProfile: Codable, Hashable, Sendable {
    var headcount: Int = 4
    var vetoes: [String] = []
    var cravings: [String] = []
    var mood: String = "Social"
}

// MARK: - Multi-Choice Group Recommendation

/// A collection of 3 curated combos for the group
struct GroupRecommendationSet: Codable, Hashable, Sendable {
    let combos: [ComboRecommendation]
}

/// A single proposed combo within the set
struct ComboRecommendation: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let optionType: String // e.g., "The Balanced Spread", "Meat Lover's Feast"
    let dishes: [RecommendedItem]
    let drinks: [DrinkRecommendation]
    let totalPrice: Double
    let reasoning: String
    let imageURL: URL?
    
    init(id: UUID = UUID(), optionType: String, dishes: [RecommendedItem], drinks: [DrinkRecommendation], totalPrice: Double, reasoning: String, imageURL: URL? = nil) {
        self.id = id
        self.optionType = optionType
        self.dishes = dishes
        self.drinks = drinks
        self.totalPrice = totalPrice
        self.reasoning = reasoning
        self.imageURL = imageURL
    }
    
    enum CodingKeys: String, CodingKey {
        case optionType, dishes, drinks, totalPrice, reasoning, imageURL
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.optionType = try container.decode(String.self, forKey: .optionType)
        self.dishes = try container.decode([RecommendedItem].self, forKey: .dishes)
        self.drinks = try container.decode([DrinkRecommendation].self, forKey: .drinks)
        self.totalPrice = try container.decode(Double.self, forKey: .totalPrice)
        self.reasoning = try container.decode(String.self, forKey: .reasoning)
        self.imageURL = try container.decodeIfPresent(URL.self, forKey: .imageURL)
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
