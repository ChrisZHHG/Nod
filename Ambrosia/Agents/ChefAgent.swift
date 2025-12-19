import Foundation

// MARK: - Agent B: The Chef (ex-Culture Agent)

class ChefAgent {
    private let service: GeminiServiceProtocol
    
    init(service: GeminiServiceProtocol = GeminiService()) {
        self.service = service
    }
    
    // MARK: - Individual Mode (Match Score)
    private func buildIndividualPrompt(profile: IndividualProfile) -> String {
        return """
        You are 'Bely', a local food expert.
        
        USER PROFILE:
        - Party Size: \(profile.partySize)
        - Budget: $\(profile.budget)
        - Taste: \(profile.tastePreference)
        - Allergies: \(profile.allergies.joined(separator: ", "))
        
        TASK:
        1. Analyze Menu.
        2. Pick ONE best dish.
        3. Explain strictly based on cultural context.
        
        OUTPUT FORMAT (JSON):
        {
          "recommendedItem": { ... },
          "translation": { "localizedName": "...", "culturalContext": "...", "warnings": [] },
          "reasoning": "...",
          "pairings": []
        }
        """
    }
    
    func recommend(from menu: MenuData, profile: IndividualProfile) async throws -> MenuRecommendation {
        print("[ChefAgent] 👨‍🍳 Cooking up Individual Recommendation...")
        let menuJSON = try String(data: JSONEncoder().encode(menu), encoding: .utf8) ?? "{}"
        let prompt = buildIndividualPrompt(profile: profile) + "\n\nMENU DATA:\n\(menuJSON)"
        
        let jsonString = try await service.generateContent(
            prompt: prompt,
            model: .pro,
            responseSchema: "application/json"
        )
        guard let data = jsonString.data(using: .utf8) else { throw NSError(domain: "ChefAgent", code: 0, userInfo: nil) }
        return try JSONDecoder().decode(MenuRecommendation.self, from: data)
    }

    // MARK: - Group Mode (The Combo Engine)
    func recommendGroupCombo(from menu: MenuData, group: GroupProfile) async throws -> ComboRecommendation {
        print("[ChefAgent] 👨‍🍳 Assembling Group Combo (Knapsack)...")
        let menuJSON = try String(data: JSONEncoder().encode(menu), encoding: .utf8) ?? "{}"
        let prompt = buildGroupPrompt(group: group) + "\n\nMENU DATA:\n\(menuJSON)"
        
        let jsonString = try await service.generateContent(
            prompt: prompt,
            model: .pro,
            responseSchema: "application/json"
        )
        guard let data = jsonString.data(using: .utf8) else { throw NSError(domain: "ChefAgent", code: 0, userInfo: nil) }
        return try JSONDecoder().decode(ComboRecommendation.self, from: data)
    }

    private func buildGroupPrompt(group: GroupProfile) -> String {
        return """
        You are 'Bely', a master event planner.
        
        GROUP PROFILE:
        - Headcount: \(group.headcount)
        - Budget: $\(group.budgetTotal)
        - Allergies (STRICT): \(group.collectiveAllergies.joined(separator: ", "))
        - Restrictions: \(group.dietaryRestrictions.joined(separator: ", "))
        - Refinement Keywords: \(group.refinementKeywords.joined(separator: ", "))
        
        TASK:
        1. [RESEARCH SIMULATION]: Identify "Signature Dishes".
        2. [COMBO]: Assemble a set (Virtual or Real) fitting requirements.
           - Rule: 1 Cold + 2 Hot + 1 Soup + 1 Carb.
           - Cost <= Budget.
           - SAFETY: ZERO violations.
        3. [DRINKS]: Recommend 3 Alcoholic + 3 Zero-Proof.
        
        OUTPUT FORMAT (JSON):
        {
          "name": "...",
          "dishes": [ ... ],
          "drinks": [ { "name": "...", "type": "Alcoholic", "description": "...", "pairingReason": "..." } ],
          "totalPrice": 120.5,
          "reasoning": "..."
        }
        """
    }
}
