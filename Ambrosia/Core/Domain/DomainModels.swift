import Foundation

/// Pure Domain Models (Schema.org compliant) - Zero UI Dependencies

struct MenuData: Codable, Hashable, Sendable {
    let sections: [MenuSection]
    let currency: String
    let languageDetected: String
    let metadata: MenuMetadata
    
    var totalItems: Int {
        sections.reduce(0) { $0 + $1.items.count }
    }
}

struct MenuMetadata: Codable, Hashable, Sendable {
    let restaurantName: String?
    let timestamp: String
    var cuisineStyle: String?
}

struct MenuSection: Codable, Identifiable, Hashable, Sendable {
    var id: String { name }
    let name: String
    let items: [MenuItem]
}

struct MenuItem: Codable, Identifiable, Hashable, Sendable {
    var id: String { originalName }
    
    let originalName: String
    let description: String?
    let price: Double?
    
    var isSpicy: Bool? = nil
    var isVegetarian: Bool? = nil
    var containsGluten: Bool? = nil
    var containsPeanuts: Bool? = nil
    var containsSeafood: Bool? = nil
    
    var matchScore: Double? = nil
}

// MARK: - Recommendation Models

struct RecommendedItem: Codable, Hashable, Sendable {
    let originalName: String
    let description: String?
    let price: Double?
    var ingredients: [String]? = nil
    var imageURL: URL? = nil
}

struct SoloRecommendationSet: Codable, Hashable, Sendable {
    let options: [MenuRecommendation]
}

struct MenuRecommendation: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let optionType: String
    let recommendedItem: RecommendedItem
    let translation: CulturalTranslation
    let reasoning: String
    let pairings: [Pairing]?
    var imageURL: URL?
    
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

// MARK: - Proxy Profile (Household Dependents)

/// A lightweight sub-profile representing a dependent (e.g., child, elderly relative)
/// who does not operate their own device. Red-line vetoes are merged into the
/// primary Chef Agent context before any recommendation is generated.
struct ProxyProfile: Codable, Hashable, Sendable, Identifiable {
    let id: UUID
    var name: String                  // e.g. "Emma (8yo)"
    var vetoes: [String]              // Hard dietary constraints, e.g. ["peanuts", "shellfish"]

    init(id: UUID = UUID(), name: String, vetoes: [String] = []) {
        self.id = id
        self.name = name
        self.vetoes = vetoes
    }
}

// MARK: - Progressive Profiles

struct IndividualProfile: Codable, Hashable, Sendable {
    var partySize: Int = 1
    var vetoes: [String] = []
    var cravings: [String] = []
    var mood: String = "Relaxed"
    /// Additional household members whose red-line vetoes are silently merged into the prompt.
    var proxyProfiles: [ProxyProfile] = []

    /// All vetoes flattened: user's own + all proxy profiles (deduplicated).
    var mergedVetoes: [String] {
        (vetoes + proxyProfiles.flatMap(\.vetoes))
            .map { $0.lowercased() }
            .reduce(into: [String]()) { if !$0.contains($1) { $0.append($1) } }
    }
}

struct GroupProfile: Codable, Hashable, Sendable {
    var headcount: Int = 4
    var vetoes: [String] = []
    var cravings: [String] = []
    var mood: String = "Social"
    /// Additional household members whose red-line vetoes are silently merged into the prompt.
    var proxyProfiles: [ProxyProfile] = []

    /// All vetoes flattened: group's own + all proxy profiles (deduplicated).
    var mergedVetoes: [String] {
        (vetoes + proxyProfiles.flatMap(\.vetoes))
            .map { $0.lowercased() }
            .reduce(into: [String]()) { if !$0.contains($1) { $0.append($1) } }
    }
}


// MARK: - Group Recommendation

struct GroupRecommendationSet: Codable, Hashable, Sendable {
    let combos: [ComboRecommendation]
}

struct ComboRecommendation: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let optionType: String
    var dishes: [RecommendedItem]
    let drinks: [DrinkRecommendation]
    let totalPrice: Double
    let reasoning: String
    var imageURL: URL?
    
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
    let type: String
    let description: String
    let pairingReason: String
}
