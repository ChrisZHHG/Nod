import Foundation

// MARK: - Agent B: The Chef (ex-Culture Agent)

final class ChefAgent: ChefAgentProtocol, @unchecked Sendable {
    private let service: GeminiServiceProtocol
    
    init(service: GeminiServiceProtocol = GeminiService()) {
        self.service = service
    }
    
    // MARK: - Individual Mode (Match Score)
    private func buildIndividualPrompt(profile: IndividualProfile, menu: MenuData) -> String {
        let cuisine = menu.metadata.cuisineStyle ?? "Unknown"
        return """
        You are 'Bely', a local food expert specializing in \(cuisine) cuisine.
        
        RESTAURANT CONTEXT: This is a \(cuisine) restaurant. Tailor your recommendation
        to the cultural norms of this cuisine (e.g., for Hotpot: suggest proteins and dipping sauce;
        for Italian: consider the pasta/risotto as a main; for Chinese: sharing-friendly dishes).
        
        USER PROFILE:
        - Party Size: \(profile.partySize)
        - Budget: $\(profile.budget)
        - Taste: \(profile.tastePreference)
        - Allergies: \(profile.allergies.joined(separator: ", "))
        
        TASK: Pick ONE best dish from the menu and explain it.
        
        Return ONLY valid JSON with this EXACT structure:
        {
          "recommendedItem": {
            "originalName": "Dish Name",
            "description": "Brief description",
            "price": 12.99
          },
          "translation": {
            "localizedName": "English Name",
            "culturalContext": "Cultural explanation",
            "warnings": []
          },
          "reasoning": "Why this dish is recommended",
          "pairings": [
            { "originalName": "Drink/Side Name", "reason": "Why it pairs well" }
          ]
        }
        """
    }

    
    func recommend(from menu: MenuData, profile: IndividualProfile) async throws -> MenuRecommendation {
        print("[ChefAgent] 👨‍🍳 Cooking up Individual Recommendation (\(menu.metadata.cuisineStyle ?? "Unknown") cuisine)...")
        let menuJSON = try String(data: JSONEncoder().encode(menu), encoding: .utf8) ?? "{}"
        let prompt = buildIndividualPrompt(profile: profile, menu: menu) + "\n\nMENU DATA:\n\(menuJSON)"
        
        let jsonString = try await service.generateContent(
            prompt: prompt,
            model: .pro,
            responseSchema: "application/json"
        )
        
        // DEBUG: Print raw response
        print("[ChefAgent] ===== RAW JSON RESPONSE =====")
        print(jsonString)
        print("[ChefAgent] ===== END RAW JSON =====")
        
        guard let data = jsonString.data(using: .utf8) else { throw NSError(domain: "ChefAgent", code: 0, userInfo: nil) }
        
        do {
            return try JSONDecoder().decode(MenuRecommendation.self, from: data)
        } catch {
            print("[ChefAgent] ❌ JSON Decode Error: \(error)")
            throw error
        }
    }

    // MARK: - Group Mode (The Combo Engine)
    func recommendGroupCombo(from menu: MenuData, group: GroupProfile) async throws -> ComboRecommendation {
        print("[ChefAgent] 👨‍🍳 Assembling Group Combo (Knapsack)...")
        let menuJSON = try String(data: JSONEncoder().encode(menu), encoding: .utf8) ?? "{}"
        let prompt = buildGroupPrompt(group: group, menu: menu) + "\n\nMENU DATA:\n\(menuJSON)"

        
        let jsonString = try await service.generateContent(
            prompt: prompt,
            model: .pro,
            responseSchema: "application/json"
        )
        
        // DEBUG: Print raw response
        print("[ChefAgent] ===== GROUP RAW JSON RESPONSE =====")
        print(jsonString)
        print("[ChefAgent] ===== END GROUP RAW JSON =====")
        
        guard let data = jsonString.data(using: .utf8) else { throw NSError(domain: "ChefAgent", code: 0, userInfo: nil) }
        
        do {
            return try JSONDecoder().decode(ComboRecommendation.self, from: data)
        } catch {
            print("[ChefAgent] ❌ Group JSON Decode Error: \(error)")
            throw error
        }
    }

    private func buildGroupPrompt(group: GroupProfile, menu: MenuData) -> String {
        let cuisine = menu.metadata.cuisineStyle ?? "Unknown"
        return """
        You are 'Bely', a master event planner specializing in \(cuisine) dining.
        
        RESTAURANT CONTEXT: \(cuisine) restaurant. Apply cuisine-specific wisdom:
        - Hotpot: recommend proteins, vegetables, and dipping sauces as a spread
        - Chinese: family-style sharing dishes that balance flavours
        - Italian: starters + main + dessert + wine pairing
        - Japanese: sashimi/sushi board + mains + drinks
        Adapt as needed for any other cuisineStyle.
        
        GROUP PROFILE:
        - Headcount: \(group.headcount)
        - Budget: $\(group.budgetTotal)
        - Allergies (STRICT): \(group.collectiveAllergies.joined(separator: ", "))
        - Restrictions: \(group.dietaryRestrictions.joined(separator: ", "))
        
        TASK: Create a group dining combo from the menu.
        
        Return ONLY valid JSON with this EXACT structure:
        {
          "name": "Combo Name",
          "dishes": [
            {"originalName": "Dish 1", "description": "...", "price": 10.99},
            {"originalName": "Dish 2", "description": "...", "price": 15.99}
          ],
          "drinks": [
            {"name": "Drink Name", "type": "Alcoholic", "description": "...", "pairingReason": "..."}
          ],
          "totalPrice": 120.50,
          "reasoning": "Why this combo works"
        }
        """
    }

}
