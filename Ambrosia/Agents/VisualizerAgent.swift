import Foundation

// MARK: - Agent D: The Visualizer (Image Generation)

final class VisualizerAgent: VisualizerAgentProtocol, @unchecked Sendable {
    private let service: GeminiServiceProtocol
    
    init(service: GeminiServiceProtocol = OpenRouterService()) {
        self.service = service
    }
    
    // "Nano Banana" (Gemini 2.5 Flash Image) or Imagen 3 standard endpoint
    private let modelID = "imagen-3.0-generate-001" 
    
    /// Fetches a real photo using the dish name and ingredients, mimicking a Google/Maps image search.
    /// Since we don't have a configured Google API Key, we use LoremFlickr with targeted keywords 
    /// as a realistic stock photo fallback.
    func visualize(dishName: String, culturalDescription: String) async throws -> URL? {
        print("[VisualizerAgent] 🎨 Painting realistic food image for: \(dishName)...")
        
        let visualPrompt = "Delicious high quality food photography of \(dishName), \(culturalDescription)"
        // Let the service handle the API call and fallback logic
        return try await service.generateImage(prompt: visualPrompt, model: modelID)
    }
}
