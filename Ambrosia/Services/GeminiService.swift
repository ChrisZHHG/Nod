import Foundation

// MARK: - Network Service

enum GeminiModel: String {
    case flash = "gemini-2.0-flash"
    case pro = "gemini-2.5-pro"  // Stable version for advanced reasoning
}


protocol GeminiServiceProtocol: AnyObject, Sendable {
    func generateContent(prompt: String, images: [Data], model: GeminiModel, responseSchema: String?) async throws -> String
    func generateImage(prompt: String, model: String) async throws -> URL?
}

// Default parameter extension to keep call sites clean if needed, 
// though we usually rely on the function signature in the protocol.
extension GeminiServiceProtocol {
    func generateContent(prompt: String, images: [Data] = [], model: GeminiModel = .flash, responseSchema: String? = nil) async throws -> String {
        return try await generateContent(prompt: prompt, images: images, model: model, responseSchema: responseSchema)
    }
}

actor GeminiService: GeminiServiceProtocol {
    private let apiKey: String?
    private let session: URLSession
    
    init() {
        // Securely read from Info.plist (which gets it from Secrets.xcconfig)
        let key = Bundle.main.object(forInfoDictionaryKey: "GeminiAPIKey") as? String
        
        if key == nil || key?.isEmpty == true || key?.contains("ReplaceWith") == true {
            print("⚠️ WARNING: Gemini API Key is missing or invalid. Calls will fail gracefully.")
            self.apiKey = nil
        } else {
            self.apiKey = key
        }
        
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
        // Priority: Custom User Key > Bundle Key
        let customKey = UserDefaults.standard.string(forKey: "custom_gemini_api_key")
        let bundleKey = self.apiKey
        
        guard let finalKey = (customKey?.isEmpty == false) ? customKey : bundleKey else {
             throw NSError(domain: "GeminiService", code: 401, userInfo: [NSLocalizedDescriptionKey: "API Key Missing. Please check Settings."])
        }
        
        let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(model.rawValue):generateContent?key=\(finalKey)")!
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
        
        let contents = ["parts": parts]
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
        
        // Clean Markdown Code Blocks (common Gemini behavior)
        var cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanText.hasPrefix("```json") {
            cleanText = cleanText.replacingOccurrences(of: "```json", with: "")
        } else if cleanText.hasPrefix("```") {
            cleanText = cleanText.replacingOccurrences(of: "```", with: "")
        }
        
        if cleanText.hasSuffix("```") {
            cleanText = String(cleanText.dropLast(3))
        }
        
        return cleanText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    // MARK: - Image Generation (Nano Banana Support)
    
    func generateImage(prompt: String, model: String) async throws -> URL? {
        // Placeholder for the Image Generation REST Endpoint
        // In real implementation, this hits: https://generativelanguage.googleapis.com/.../models/{model}:predict
        
        // Mocking the behavior for PoC stability (since Image Gen API requires specific separate billing often)
        // Returning a high-quality placeholder image of generic food for demo purposes
        print("[GeminiService] Generating image with model: \(model)")
        try await Task.sleep(nanoseconds: 2_000_000_000)
        
        // Return a mock LoremFlickr URL with "food" tag to avoid random non-food images (like ferris wheels)
        // Adding a lock ensures consistency per prompt hash
        let hash = abs(prompt.hashValue % 1000)
        return URL(string: "https://loremflickr.com/800/600/food,dinner?lock=\(hash)")
    }
}
