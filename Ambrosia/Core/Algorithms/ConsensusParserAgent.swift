import Foundation

// MARK: - Core/Algorithms: Phase 8 Consensus Parser
// Conforms to Principles 4 & 5. This agent strictly parses unstructured natural language
// into a typed `ComboRecommendation` to bridge the Chat UI back to the Results UI.

final class ConsensusParserAgent: @unchecked Sendable {
    private let service: GeminiServiceProtocol
    
    init(service: GeminiServiceProtocol = OpenRouterService()) {
        self.service = service
    }
    
    func parseConsensus(rawText: String, menuData: MenuData?) async throws -> ComboRecommendation {
        var menuString = "Unknown Menu"
        if let menu = menuData, let data = try? JSONEncoder().encode(menu), let str = String(data: data, encoding: .utf8) {
            menuString = str
        }
        
        let systemPrompt = """
        You are an expert data structured parser. The user will provide a raw text string containing a multi-agent consensus of chosen dishes from a negotiation.
        Your job is to match these dishes against the provided MENU DATA to reconstruct their exact prices, descriptions, and ingredients, and return a STRICT JSON output representing the group's chosen meal combo.
        
        RETURN EXACTLY THIS JSON STRUCTURE:
        {
          "optionType": "AI Consensus Pick",
          "dishes": [
            {
              "originalName": "Exact Dish Name from Menu",
              "description": "Matched Description from Menu",
              "price": 12.0,
              "ingredients": ["Extracted", "Ingredients"]
            }
          ],
          "drinks": [],
          "totalPrice": 36.0,
          "reasoning": "A perfect compromise based on the group's negotiations."
        }
        
        MENU DATA:
        \(menuString)
        """
        
        let prompt = "\(systemPrompt)\n\nRAW USER INPUT TO PARSE:\n\(rawText)"
        
        let jsonString = try await service.generateContent(
            prompt: prompt,
            model: .flash,
            responseSchema: "application/json"
        )
        
        guard let data = jsonString.data(using: .utf8) else {
            throw AmbrosiaError.recommendationFailed(reason: "Consensus Parser returned empty data.")
        }
        
        let decoder = JSONDecoder()
        do {
            let combo = try decoder.decode(ComboRecommendation.self, from: data)
            return combo
        } catch {
            print("[ConsensusParserAgent] JSON Decode Error: \(error)")
            throw AmbrosiaError.recommendationFailed(reason: "Failed to decode Consensus JSON: \(error.localizedDescription)")
        }
    }
}
