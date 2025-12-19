import Foundation

// MARK: - Network Service

enum GeminiModel: String {
    case flash = "gemini-3-flash-preview" // Updated to Gemini 3.0 Flash Preview
    case pro = "gemini-1.5-pro"           // Keeping 1.5 Pro
}

actor GeminiService {
    private let apiKey: String
    private let session: URLSession
    
    init(apiKey: String = "YOUR_API_KEY") { // To be injected or loaded from Config
        self.apiKey = apiKey
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30.0 // Reasonable timeout for Vision
        self.session = URLSession(configuration: config)
    }
    
    /// Sends text + images to Gemini and expects a JSON response
    func generateContent(
        prompt: String,
        images: [Data] = [],
        model: GeminiModel = .flash,
        responseSchema: String? = nil // Optional JSON Schema enforcement
    ) async throws -> String {
        
        let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(model.rawValue):generateContent?key=\(apiKey)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Build Payload
        let requestBody = buildRequestBody(prompt: prompt, images: images, schema: responseSchema)
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown Error"
            throw NSError(domain: "GeminiService", code: (response as? HTTPURLResponse)?.statusCode ?? 500, userInfo: [NSLocalizedDescriptionKey: errorText])
        }
        
        // Parse Response
        return try parseResponse(data)
    }
    
    private func buildRequestBody(prompt: String, images: [Data], schema: String?) -> [String: Any] {
        var parts: [[String: Any]] = []
        
        // Add Prompt
        parts.append(["text": prompt])
        
        // Add Images
        for imageData in images {
            parts.append([
                "inline_data": [
                    "mime_type": "image/jpeg",
                    "data": imageData.base64EncodedString()
                ]
            ])
        }
        
        var contents = ["parts": parts]
        var body: [String: Any] = [
            "contents": [contents]
        ]
        
        // Force JSON Output if schema is needed (Gemini feature)
        if schema != nil {
            body["generationConfig"] = [
                "response_mime_type": "application/json"
            ]
        }
        
        return body
    }
    
    private func parseResponse(_ data: Data) throws -> String {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let content = candidates.first?["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let text = parts.first?["text"] as? String else {
            throw NSError(domain: "Parsing", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON Structure"])
        }
        return text
    }
    // MARK: - Image Generation (Nano Banana Support)
    
    func generateImage(prompt: String, model: String) async throws -> URL? {
        // Placeholder for the Image Generation REST Endpoint
        // In real implementation, this hits: https://generativelanguage.googleapis.com/.../models/{model}:predict
        
        // Mocking the behavior for PoC stability (since Image Gen API requires specific separate billing often)
        // Returning a high-quality placeholder image of generic food for demo purposes
        print("[GeminiService] Generating image with model: \(model)")
        try await Task.sleep(nanoseconds: 2_000_000_000)
        
        // Return a mock Lorem Picsum URL based on the hash of the prompt for consistency
        let hash = abs(prompt.hashValue % 1000)
        return URL(string: "https://picsum.photos/id/\(hash)/800/600")
    }
}
