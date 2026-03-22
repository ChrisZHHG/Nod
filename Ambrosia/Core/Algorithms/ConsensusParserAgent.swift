import Foundation

// MARK: - Core/Algorithms: Phase 8 Consensus Parser
// Conforms to Principles 4 & 5. This agent bridges the A2A Chat back to the Results UI.
// Primary path: extracts dish names from the structured JSON consensus signal, then calls
// the LLM to hydrate each dish with full menu metadata.
// Fallback path: handles legacy [CONSENSUS REACHED] keyword for backwards compatibility.

final class ConsensusParserAgent: @unchecked Sendable {
    private let service: GeminiServiceProtocol

    init(service: GeminiServiceProtocol = OpenRouterService()) {
        self.service = service
    }

    func parseConsensus(rawText: String, menuData: MenuData?) async throws -> ComboRecommendation {
        // Step 1: Extract dish names from the structured consensus signal (JSON-first, keyword fallback).
        let consensusSignal = ConsensusDetector.extractConsensus(from: rawText)
        let extractedDishNames = consensusSignal?.dishes ?? []

        var menuString = "Unknown Menu"
        if let menu = menuData, let data = try? JSONEncoder().encode(menu), let str = String(data: data, encoding: .utf8) {
            menuString = str
        }

        // Step 2: Build the hydration prompt.
        // If we have structured dish names, inject them directly so the LLM doesn't have to guess.
        let dishNamesHint: String
        if !extractedDishNames.isEmpty {
            dishNamesHint = "The agreed dishes are: \(extractedDishNames.joined(separator: ", ")). Match each EXACTLY against the menu."
        } else {
            dishNamesHint = "Parse the raw input below to identify the agreed dishes, then match them against the menu."
        }

        let systemPrompt = """
        You are an expert data structured parser. \(dishNamesHint)
        Return a STRICT JSON object representing the group's chosen meal combo.

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

        let prompt = "\(systemPrompt)\n\nRAW INPUT:\n\(rawText)"

        let jsonString = try await service.generateContent(
            prompt: prompt,
            model: .flash,
            responseSchema: "application/json"
        )

        guard let data = jsonString.data(using: .utf8) else {
            throw NodError.recommendationFailed(reason: "Consensus Parser returned empty data.")
        }

        do {
            return try JSONDecoder().decode(ComboRecommendation.self, from: data)
        } catch {
            throw NodError.recommendationFailed(reason: "Failed to decode Consensus JSON: \(error.localizedDescription)")
        }
    }
}
