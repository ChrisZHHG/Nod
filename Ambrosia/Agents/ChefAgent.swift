import Foundation

// MARK: - Agent B: The Chef (ex-Culture Agent)

final class ChefAgent: ChefAgentProtocol, @unchecked Sendable {
    private let service: GeminiServiceProtocol
    
    init(service: GeminiServiceProtocol = OpenRouterService()) {
        self.service = service
    }
    
    // MARK: - Individual Mode (Multi-Choice)
    private func buildIndividualPrompt(profile: IndividualProfile, menu: MenuData, research: RestaurantResearchData?) -> String {
        let cuisine = menu.metadata.cuisineStyle ?? "Unknown"
        return """
        You are 'Bely', a world-class AI Sommelier and local food expert specializing in \(cuisine) cuisine.
        
        RESTAURANT CONTEXT: This is a \(cuisine) restaurant. Tailor your recommendation to its cultural norms.
        
        USER PROFILE & ENVIRONMENTAL CONTEXT:
        - Party Size: \(profile.partySize)
        - Vetoes/Allergies (STRICT AVOIDANCE): \(profile.vetoes.isEmpty ? "None" : profile.vetoes.joined(separator: ", "))
        - Cravings/Preferences: \(profile.cravings.isEmpty ? "None" : profile.cravings.joined(separator: ", "))
        - User's Mood/Vibe: \(profile.mood)
        
        GOOGLE PLACES RESEARCH (IF AVAILABLE):
        - General Vibe: \(research?.generalVibe ?? "Not available")
        - Rating: \(research?.rating.map { "\($0) stars" } ?? "Not available")
        - Popular Dishes/Specialties (Prioritize these if they match cravings and avoid vetoes): \(research?.popularDishes.isEmpty == false ? research!.popularDishes.joined(separator: ", ") : "Not available")
        
        TASK:
        The customer requested personalized options. You must provide EXACTLY THREE distinct choices from the provided MENU DATA.
        
        CRITICAL INSTRUCTIONS: 
        1. You MUST ONLY select dishes that exist in the provided MENU DATA. DO NOT invent or hallucinate dishes.
        2. Your `reasoning` must be highly persuasive and explicitly mention how the dish matches the user's `Mood` or `Cravings`.
        3. For `optionType`, create a SHORT (2-4 words), EVOCATIVE, MOOD-DRIVEN label that captures the personality of that recommendation — based on the user's mood and the dish character. Examples: "Grand Feast", "Light & Fresh", "Hidden Gem", "Crowd Pleaser", "Bold Adventure", "Soul Food", "Chef's Secret". Make it feel like a recommendation personality, not a category name.
        
        Return ONLY valid JSON with this EXACT structure:
        {
          "options": [
            {
              "optionType": "Grand Feast",
              "recommendedItem": {
                "originalName": "Dish Name from Menu",
                "description": "Brief description",
                "price": 12.99,
                "ingredients": ["Tomato", "Basil", "Mozzarella"]
              },
              "translation": {
                "localizedName": "English Name if dish is in foreign language, otherwise same as originalName",
                "culturalContext": "1-2 sentence cultural explanation and why it fits this user's vibe",
                "warnings": []
              },
              "reasoning": "Why this fits their mood and cravings.",
              "pairings": [
                { "originalName": "Drink/Side Name", "reason": "Why it pairs well" }
              ]
            }
          ]
        }
        (Ensure you output 3 items in the `options` array with 3 distinct `optionType` mood labels).
        """
    }

    
    func recommend(from menu: MenuData, profile: IndividualProfile, research: RestaurantResearchData?) async throws -> SoloRecommendationSet {
        print("[ChefAgent] 👨‍🍳 Cooking up Individual Recommendation (\(menu.metadata.cuisineStyle ?? "Unknown") cuisine)...")
        let menuJSON = try String(data: JSONEncoder().encode(menu), encoding: .utf8) ?? "{}"
        let prompt = buildIndividualPrompt(profile: profile, menu: menu, research: research) + "\n\nMENU DATA:\n\(menuJSON)"
        
        let jsonString = try await service.generateContent(
            prompt: prompt,
            model: .pro, // Utilizing Claude 3.5 Sonnet mapping for higher reasoning
            responseSchema: "application/json"
        )
        
        // DEBUG: Print raw response
        print("[ChefAgent] ===== RAW JSON RESPONSE =====")
        print(jsonString)
        print("[ChefAgent] ===== END RAW JSON =====")
        
        guard let data = jsonString.data(using: .utf8) else {
            throw NodError.reasoningFailed(reason: "Chef AI returned an empty response.")
        }
        
        do {
            return try JSONDecoder().decode(SoloRecommendationSet.self, from: data)
        } catch {
            print("[ChefAgent] [ERROR] JSON Decode Error: \(error)")
            throw NodError.reasoningFailed(reason: "The Chef's response format was unexpected. Re-submitting usually fixes this.")
        }
    }

    // MARK: - Group Mode (The Combo Engine)
    func recommendGroupCombo(from menu: MenuData, group: GroupProfile, research: RestaurantResearchData?) async throws -> GroupRecommendationSet {
        print("[ChefAgent] 👨‍🍳 Assembling Group Combos...")
        let menuJSON = try String(data: JSONEncoder().encode(menu), encoding: .utf8) ?? "{}"
        let prompt = buildGroupPrompt(group: group, menu: menu, research: research) + "\n\nMENU DATA:\n\(menuJSON)"

        let jsonString = try await service.generateContent(
            prompt: prompt,
            model: .pro, // Utilizing Claude 3.5 Sonnet mapping for sophisticated group combos
            responseSchema: "application/json"
        )
        
        guard let data = jsonString.data(using: .utf8) else {
            throw NodError.reasoningFailed(reason: "Chef AI returned an empty response for group combo.")
        }
        
        do {
            return try JSONDecoder().decode(GroupRecommendationSet.self, from: data)
        } catch {
            print("[ChefAgent] [ERROR] Group JSON Decode Error: \(error)")
            throw NodError.reasoningFailed(reason: "The Chef's group combo format was unexpected.")
        }
    }

    private func buildGroupPrompt(group: GroupProfile, menu: MenuData, research: RestaurantResearchData?) -> String {
        let cuisine = menu.metadata.cuisineStyle ?? "Unknown"
        
        // Only include drinks if the menu actually has a drink/beverage section
        let drinkKeywords = ["drink", "beverage", "cocktail", "wine", "beer", "alcohol", "spirits", "juice", "soda", "bar"]
        let drinkSections = menu.sections.filter { section in
            drinkKeywords.contains(where: { section.name.lowercased().contains($0) })
        }
        let hasDrinksMenu = !drinkSections.isEmpty
        
        let drinksInstruction = hasDrinksMenu
            ? "DRINKS: Recommend 1-2 drinks from the drinks/beverage sections only. Do NOT invent drinks not on the menu."
            : "DRINKS: The menu does not have a drinks section. Set `drinks` to an empty array `[]`. Do NOT invent or hallucinate drinks."
        
        return """
        You are 'Bely', a master event planner and Sommelier specializing in \(cuisine) dining.
        
        RESTAURANT CONTEXT: \(cuisine) restaurant. Apply cuisine-specific wisdom for sharing.
        
        GROUP PROFILE & ENVIRONMENTAL CONTEXT:
        - Headcount: \(group.headcount)
        - Vetoes/Allergies (STRICT AVOIDANCE): \(group.vetoes.isEmpty ? "None" : group.vetoes.joined(separator: ", "))
        - Cravings/Preferences: \(group.cravings.isEmpty ? "None" : group.cravings.joined(separator: ", "))
        - Group Vibe/Mood: \(group.mood)
        
        GOOGLE PLACES RESEARCH (IF AVAILABLE):
        - General Vibe: \(research?.generalVibe ?? "Not available")
        - Rating: \(research?.rating.map { "\($0) stars" } ?? "Not available")
        - Popular Dishes/Specialties (Prioritize these if they match cravings and avoid vetoes): \(research?.popularDishes.isEmpty == false ? research!.popularDishes.joined(separator: ", ") : "Not available")
        
        TASK:
        The group is sharing plates. Create EXACTLY THREE completely different combo sets that avoid all vetoes, choosing ONLY from the provided MENU DATA:
        1. "The Balanced Spread" (A perfect mix of proteins, veg, and carbs)
        2. "The Heavy Feast" (Or vegetarian equivalent, depending on cravings)
        3. "The Chef's Tasting" (A premium, varied selection)
        
        CRITICAL INSTRUCTIONS: 
        1. You MUST ONLY select dishes that exist in the provided MENU DATA. DO NOT invent or hallucinate dishes.
        2. EXCLUDE ANY DISH that contains ANY of the Vetoes/Allergies (\(group.vetoes.isEmpty ? "None" : group.vetoes.joined(separator: ", "))). This is a fatal safety violation if missed.
        3. QUANTITY: The combos MUST contain enough distinct dishes to satisfy exactly \(group.headcount) people. (e.g. 4 people = ~5-7 dishes).
        4. Your `reasoning` must highly explicitly mention how the combo matches the group's `Mood` or `Cravings`.
        5. \(drinksInstruction)
        
        Return ONLY valid JSON with this EXACT structure:
        {
          "combos": [
            {
              "optionType": "The Balanced Spread",
              "dishes": [
                {"originalName": "Dish 1", "description": "...", "price": 10.99, "ingredients": ["Tofu", "Chili"]},
                {"originalName": "Dish 2", "description": "...", "price": 15.99, "ingredients": ["Beef", "Broccoli"]}
              ],
              "drinks": [],
              "totalPrice": 120.50,
              "reasoning": "Why this combo works for their vibe."
            }
          ]
        }
        (Ensure you output 3 items in the `combos` array).
        """
    }

}
