import Foundation

/// Defines the contract for external research (e.g., Google Places API)
protocol ResearchAgentProtocol: Sendable {
    func researchRestaurant(name: String, location: String?) async throws -> RestaurantResearchData
}

struct RestaurantResearchData: Codable, Hashable, Sendable {
    let popularDishes: [String]
    let generalVibe: String
    let rating: Double?
}

/// A live implementation connecting to the Google Places API (New)
final class ResearchAgent: ResearchAgentProtocol {
    
    private let apiKey: String?
    private let session: URLSession
    
    init() {
        let key = Bundle.main.object(forInfoDictionaryKey: "GooglePlacesAPIKey") as? String
        if let key, !key.isEmpty, !key.contains("ReplaceWith") {
            self.apiKey = key
        } else {
            print("⚠️ WARNING: Google Places API Key missing. Set GOOGLE_PLACES_API_KEY in Secrets.xcconfig.")
            self.apiKey = nil
        }
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15.0 // Fail fast to prioritize UX
        self.session = URLSession(configuration: config)
    }
    
    func researchRestaurant(name: String, location: String?) async throws -> RestaurantResearchData {
        guard let apiKey else {
            print("[ResearchAgent] API key missing. Falling back to default data.")
            return fallbackData()
        }
        
        print("[ResearchAgent] 🔎 Searching Google Places for '\(name)'...")
        
        // 1. Text Search API (New) to find the Place ID and core details
        guard let searchURL = URL(string: "https://places.googleapis.com/v1/places:searchText") else {
            print("[ResearchAgent] [ERROR] Malformed search URL.")
            return fallbackData()
        }
        
        var request = URLRequest(url: searchURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "X-Goog-Api-Key")
        // Request exactly what we need for the ChefAgent LLM context
        request.setValue("places.id,places.displayName,places.rating,places.priceLevel,places.editorialSummary,places.reviews", forHTTPHeaderField: "X-Goog-FieldMask")
        
        // Enhance precision if location hint is provided
        let query = location != nil ? "\(name) near \(location!)" : name
        let body: [String: Any] = ["textQuery": query]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            print("[ResearchAgent] ❌ Google API Error: \((response as? HTTPURLResponse)?.statusCode ?? 500)")
            return fallbackData()
        }
        
        let places = try parsePlacesResponse(data)
        
        print("[ResearchAgent] ✨ Extracted Vibe: '\(places.generalVibe.prefix(80))...'")
        return places
    }
    
    private func parsePlacesResponse(_ data: Data) throws -> RestaurantResearchData {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let places = json["places"] as? [[String: Any]],
              let firstPlace = places.first else {
            return fallbackData()
        }
        
        let rating = firstPlace["rating"] as? Double
        
        // Build the Vibe String
        var vibeComponents: [String] = []
        
        // 1. Editorial Summary
        if let summaryDict = firstPlace["editorialSummary"] as? [String: Any],
           let text = summaryDict["text"] as? String {
            vibeComponents.append(text)
        }
        
        // 2. Extract sentiment or popular items from top 3 reviews
        var popularMentions: [String] = []
        if let reviews = firstPlace["reviews"] as? [[String: Any]] {
            for review in reviews.prefix(3) {
                if let textDict = review["text"] as? [String: Any],
                   let reviewText = textDict["text"] as? String {
                    // Extract a highly truncated snippet to feed the LLM context
                    vibeComponents.append("\"\(String(reviewText.prefix(150)))...\"")
                }
            }
        }
        
        let finalVibe = vibeComponents.isEmpty ? "No specific atmosphere listed." : vibeComponents.joined(separator: " | ")
        
        return RestaurantResearchData(
            popularDishes: popularMentions, // Will be extracted directly from menu parsing vs cross-referencing in the future
            generalVibe: finalVibe,
            rating: rating
        )
    }
    
    private func fallbackData() -> RestaurantResearchData {
        return RestaurantResearchData(
            popularDishes: [],
            generalVibe: "A mysterious, newly discovered spot.",
            rating: nil
        )
    }
}
