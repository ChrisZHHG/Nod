import Foundation

// MARK: - Agent A: The Eye (Decoder)

class DecoderAgent {
    private let service = GeminiService()
    
    /// The System Prompt that forces VDU (Visual Document Understanding)
    private let systemPrompt = """
    You are an expert Menu Digitizer (VDU Agent). 
    Analyze the provided menu images. 
    Identify the semantic structure: Sections (e.g., Appetizers, Mains, Drinks) and Items.
    
    CRITICAL RULES:
    1. Extract the EXACT original name of the dish.
    2. Identify the currency.
    3. Infer dietary tags (Spicy, Vegetarian, Gluten, Peanut, Seafood) based on description/icon/knowledge.
    4. Return ONLY valid JSON matching this structure:
    {
      "sections": [
        { "name": "Section Name", "items": [ { "originalName": "", "description": "", "price": 0.0, "isSpicy": false, ... } ] }
      ],
      "currency": "USD",
      "languageDetected": "en",
      "metadata": { "restaurantName": "Detected Name or Unknown", "timestamp": "..." }
    }
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
        
        // Decode JSON to Struct
        guard let data = jsonString.data(using: .utf8) else {
            throw NSError(domain: "Decoder", code: 0, userInfo: [NSLocalizedDescriptionKey: "Empty Response"])
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(MenuData.self, from: data)
    }
}
