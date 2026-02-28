import Foundation

// MARK: - OpenRouter Model IDs

enum OpenRouterModel: String {
    /// Best all-rounder for vision + text — cheap & very capable
    case geminiFlash   = "google/gemini-2.0-flash-001"
    /// State-of-the-art reasoning model for complex food pairings and nuanced prose
    case claudeSonnet  = "anthropic/claude-3.5-sonnet:beta"
    /// Deep, open-weights fallback
    case llama70B      = "meta-llama/llama-3.3-70b-instruct"
    /// Free tier vision model — good fallback (rate-limited)
    case llamaVision   = "meta-llama/llama-3.2-11b-vision-instruct:free"
}

// MARK: - OpenRouter Service

/// Drop-in replacement for GeminiService.
/// Uses OpenRouter's OpenAI-compatible endpoint:
/// POST https://openrouter.ai/api/v1/chat/completions
///
/// Vision images are passed as base64 data URLs in the message content array.
actor OpenRouterService: GeminiServiceProtocol {

    private let apiKey: String?
    private let session: URLSession
    private let baseURL = "https://openrouter.ai/api/v1/chat/completions"

    init() {
        let key = Bundle.main.object(forInfoDictionaryKey: "OpenRouterAPIKey") as? String
        if let key, !key.isEmpty, !key.contains("ReplaceWith") {
            self.apiKey = key
        } else {
            print("⚠️ WARNING: OpenRouter API Key missing. Set OPENROUTER_API_KEY in Secrets.xcconfig.")
            self.apiKey = nil
        }

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60.0
        self.session = URLSession(configuration: config)
    }

    // MARK: - GeminiServiceProtocol conformance

    /// Sends a text prompt + optional images to OpenRouter and returns the text response.
    func generateContent(
        prompt: String,
        images: [Data] = [],
        model: GeminiModel = .flash,         // mapped → OpenRouter model
        responseSchema: String? = nil
    ) async throws -> String {
        guard let apiKey else {
            throw NSError(domain: "OpenRouterService", code: 401,
                          userInfo: [NSLocalizedDescriptionKey: "OpenRouter API key not configured."])
        }

        let orModel = mapModel(model)

        // Build message content — text first, then inline images
        var contentParts: [[String: Any]] = [["type": "text", "text": prompt]]
        for imageData in images {
            let b64 = imageData.base64EncodedString()
            contentParts.append([
                "type": "image_url",
                "image_url": ["url": "data:image/jpeg;base64,\(b64)"]
            ])
        }

        var body: [String: Any] = [
            "model": orModel,
            "messages": [["role": "user", "content": contentParts]],
            // Push for slightly higher creativity in food descriptions
            "temperature": 0.7 
        ]

        // Ask for JSON output when schema is requested
        if responseSchema != nil {
            body["response_format"] = ["type": "json_object"]
        }

        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("https://github.com/ChrisZHHG/Ambrosia", forHTTPHeaderField: "HTTP-Referer")
        request.setValue("Ambrosia-iOS", forHTTPHeaderField: "X-Title")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown Error"
            let code = (response as? HTTPURLResponse)?.statusCode ?? 500
            throw NSError(domain: "OpenRouterService", code: code,
                          userInfo: [NSLocalizedDescriptionKey: errorText])
        }

        return try parseResponse(data)
    }

    /// Fallback Image Generation using Pollinations.ai (Free, no API key required text-to-image)
    /// Since OpenRouter doesn't natively support image generation (DALL-E etc).
    func generateImage(prompt: String, model: String) async throws -> URL? {
        print("[OpenRouterService] Generating image via Pollinations.ai...")
        
        // Force 'flux' model for significantly better photorealism compared to default turbo models.
        // Also append strict style guidelines to the raw prompt to prevent cartoonish/abstract renders.
        let augmentedPrompt = "\(prompt), highly detailed food photography, depth of field, natural lighting, bokeh, 8k resolution, photorealistic"
        
        // Encode the prompt for a URL path
        guard let encodedPrompt = augmentedPrompt.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            return nil
        }
        
        let endpoint = "https://image.pollinations.ai/prompt/\(encodedPrompt)?width=800&height=800&nologo=true&model=flux"
        return URL(string: endpoint)
    }

    // MARK: - Private helpers

    private func mapModel(_ model: GeminiModel) -> String {
        switch model {
        case .flash: return OpenRouterModel.geminiFlash.rawValue
        case .pro:   return OpenRouterModel.claudeSonnet.rawValue  // Map 'pro' requests to Claude 3.5 Sonnet for top-tier reasoning
        }
    }

    private func parseResponse(_ data: Data) throws -> String {
        guard
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let choices = json["choices"] as? [[String: Any]],
            let message = choices.first?["message"] as? [String: Any],
            let content = message["content"] as? String
        else {
            let raw = String(data: data, encoding: .utf8) ?? ""
            throw NSError(domain: "OpenRouterService", code: 0,
                          userInfo: [NSLocalizedDescriptionKey: "Unexpected response: \(raw)"])
        }

        // Strip markdown code fences if the model wraps JSON in ```json ... ```
        var clean = content.trimmingCharacters(in: .whitespacesAndNewlines)
        if clean.hasPrefix("```json") { clean = String(clean.dropFirst(7)) }
        else if clean.hasPrefix("```")  { clean = String(clean.dropFirst(3)) }
        if clean.hasSuffix("```")       { clean = String(clean.dropLast(3)) }
        return clean.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
