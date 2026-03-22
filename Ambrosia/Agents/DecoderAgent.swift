import Foundation

// MARK: - Agent A: The Eye (Decoder)

final class DecoderAgent: DecoderAgentProtocol, @unchecked Sendable {
    private let service: GeminiServiceProtocol
    
    init(service: GeminiServiceProtocol = OpenRouterService()) {
        self.service = service
    }
    
    /// The System Prompt that forces VDU (Visual Document Understanding)
    private let systemPrompt = """
    You are an expert Menu Digitizer. Analyze the provided menu images.
    
    Return ONLY valid JSON with this EXACT structure (no extra fields, no missing fields):
    {
      "sections": [
        {
          "name": "Section Name",
          "items": [
            {
              "originalName": "Dish Name",
              "description": "Brief description or null",
              "price": 12.99,
              "isSpicy": false,
              "isVegetarian": false,
              "containsGluten": false,
              "containsPeanuts": false,
              "containsSeafood": false
            }
          ]
        }
      ],
      "currency": "USD",
      "languageDetected": "en",
      "metadata": {
        "restaurantName": "Restaurant Name or Unknown",
        "timestamp": "2024-12-24T12:00:00Z",
        "cuisineStyle": "Chinese"
      }
    }
    
    RULES:
    - Extract exact dish names from the menu
    - Infer dietary tags based on ingredients/icons.
    - If you are NOT 100% sure about a dietary tag (e.g. containsGluten), return null instead of false.
    - Use null for missing descriptions
    - Price should be a number, not a string
    - For cuisineStyle: infer from dish names, language, and visual cues.
      Use ONE of: "Chinese", "Japanese", "Korean", "Thai", "Vietnamese", "Hotpot",
      "Italian", "French", "American", "Mexican", "Indian", "Fusion", or "Unknown".
    """

    
    func decode(images: [Data]) async throws -> MenuData {
        print("[DecoderAgent] Sending \(images.count) images to Gemini Flash...")

        let jsonString = try await service.generateContent(
            prompt: systemPrompt,
            images: images,
            model: .flash,
            responseSchema: "application/json"
        )

        print("[DecoderAgent] ===== RAW JSON RESPONSE =====")
        print(jsonString)
        print("[DecoderAgent] ===== END RAW JSON =====")

        // Sanity check: if the model returned a plain English refusal (no JSON braces),
        // throw a clean user-facing error instead of a confusing Swift decode error.
        guard jsonString.contains("{") else {
            print("[DecoderAgent] [ERROR] Non-JSON response: \(jsonString.prefix(200))")
            throw NodError.decodingFailed(reason: "Could not read the menu. Try a clearer photo with the full menu visible.")
        }

        guard let data = jsonString.data(using: .utf8) else {
            throw NodError.decodingFailed(reason: "Menu AI returned an empty response. Please try again.")
        }

        do {
            return try JSONDecoder().decode(MenuData.self, from: data)
        } catch {
            print("[DecoderAgent] [ERROR] JSON Decode Error: \(error)")
            // Provide actionable guidance rather than a raw Swift type error.
            throw NodError.decodingFailed(reason: "The AI response format was unexpected. Retaking the photo usually fixes this.")
        }
    }
}
