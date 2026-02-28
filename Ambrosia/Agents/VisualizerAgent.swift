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
        
        // We use Pollinations.ai with a highly specific prompt to avoid hallucinations
        // like drawing a literal cat for a dish named "Naughty Cat".
        let visualPrompt = "Delicious high quality food photography of \(dishName), \(culturalDescription). Appetizing, professional culinary lighting, 8k resolution, photorealistic."
        let cleanPrompt = visualPrompt.replacingOccurrences(of: "\n", with: " ")
        
        guard let encodedPrompt = cleanPrompt.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            return nil
        }
        
        // nologo=true removes the watermark, enhance=true makes the image strictly follow the prompt better
        let endpoint = "https://image.pollinations.ai/prompt/\(encodedPrompt)?width=800&height=800&nologo=true&enhance=true"
        
        return URL(string: endpoint)
    }
}
