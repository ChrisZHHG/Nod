import Foundation

// MARK: - Agent A: The Eye (Decoder)

final class DecoderAgent: DecoderAgentProtocol, @unchecked Sendable {
    private let service: GeminiServiceProtocol
    
    init(service: GeminiServiceProtocol = GeminiService()) {
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
        "timestamp": "2024-12-24T12:00:00Z"
      }
    }
    
    RULES:
    - Extract exact dish names from the menu
    - Infer dietary tags based on ingredients/icons.
    - If you are NOT 100% sure about a dietary tag (e.g. containsGluten), return null instead of false.
    - Use null for missing descriptions
    - Price should be a number, not a string
    """
    
    func decode(images: [Data]) async throws -> MenuData {
        // "Silky" UX: We tell the Manager we are starting text recognition
        print("[DecoderAgent] Sending \(images.count) images to Gemini Flash...")
        
        // Call API
        let jsonString = try await service.generateContent(
            prompt: systemPrompt,
            images: images,
            model: .flash,
            responseSchema: "application/json" // Force strict JSON
        )
        
        // DEBUG: Print raw response to diagnose parsing issues
        print("[DecoderAgent] ===== RAW JSON RESPONSE =====")
        print(jsonString)
        print("[DecoderAgent] ===== END RAW JSON =====")
        
        // Decode JSON to Struct
        guard let data = jsonString.data(using: .utf8) else {
            throw NSError(domain: "Decoder", code: 0, userInfo: [NSLocalizedDescriptionKey: "Empty Response"])
        }
        
        let decoder = JSONDecoder()
        
        do {
            return try decoder.decode(MenuData.self, from: data)
        } catch {
            print("[DecoderAgent] ❌ JSON Decode Error: \(error)")
            throw error
        }
    }
}
