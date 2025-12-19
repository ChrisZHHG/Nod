import Foundation

// MARK: - Agent B: The Brain (Culture Agent)

class CultureAgent {
    private let service: GeminiServiceProtocol
    
    init(service: GeminiServiceProtocol = GeminiService()) {
        self.service = service
    }
    
    /// The System Prompt that defines the "Bely Persona"
    /// Enforces "Explanation" over "Translation" and solves the Knapsack problem.
    private func buildSystemPrompt(profile: UserProfile) -> String {
        return """
        You are 'Bely', a local food expert and sommelier.
        
        USER PROFILE:
        - Party Size: \(profile.partySize)
        - Budget: $\(profile.budget)
        - Taste: \(profile.tastePreference)
        - Allergies: \(profile.allergies.joined(separator: ", ")) (CRITICAL: AVOID THESE)
        
        TASK:
        1. Analyze the provided Menu Data (JSON).
        2. Select the BEST combination of dishes that fits the Budget.
        3. Do NOT just translate. INTERPRET the dish.
           - Example: "Husband Wife Lung Slices" -> "Spicy Beef & Tripe (Served Cold)".
           - Explain WHY it fits the user's taste.
        
        OUTPUT FORMAT (JSON):
        {
          "recommendedItem": { ...copy precise item details... },
          "translation": {
            "localizedName": "Cultural Name",
            "culturalContext": "Explanation of texture/flavor...",
            "warnings": ["Spicy", "Offal"]
          },
          "reasoning": "I chose this because...",
          "pairings": ["Drink A", "Side B"]
        }
        """
    }
    
    func recommend(from menu: MenuData, profile: UserProfile) async throws -> MenuRecommendation {
        print("[CultureAgent] 🧠 Injecting Bely Persona & Solving Knapsack problem...")
        
        // Convert input menu to JSON string for context
        let menuJSON = try String(data: JSONEncoder().encode(menu), encoding: .utf8) ?? "{}"
        let prompt = buildSystemPrompt(profile: profile) + "\n\nMENU DATA:\n\(menuJSON)"
        
        // Call Gemini 3.0 Flash (The latest standard)
        // Flash 3.0 serves as the primary reasoning engine for speed+intelligence balance
        let jsonString = try await service.generateContent(
            prompt: prompt,
            model: .flash,
            responseSchema: "application/json"
        )
        
        guard let data = jsonString.data(using: .utf8) else {
             throw NSError(domain: "CultureAgent", code: 0, userInfo: [NSLocalizedDescriptionKey: "Empty Response"])
        }
        
        return try JSONDecoder().decode(MenuRecommendation.self, from: data)
    }
}
