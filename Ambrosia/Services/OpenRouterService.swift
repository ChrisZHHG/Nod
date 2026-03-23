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

    /// Safe URL constructed once at init to avoid force-unwrap crashes at call sites.
    private let endpointURL: URL

    /// Retry policy for transient failures (429 rate-limit, 503 overload).
    private let maxRetries = 3
    private let retryableStatusCodes: Set<Int> = [429, 500, 502, 503, 504]

    init() {
        let key = Bundle.main.object(forInfoDictionaryKey: "OpenRouterAPIKey") as? String
        if let key, !key.isEmpty, !key.contains("ReplaceWith") {
            self.apiKey = key
        } else {
            print("⚠️ WARNING: OpenRouter API Key missing. Set OPENROUTER_API_KEY in Secrets.xcconfig.")
            self.apiKey = nil
        }

        // Build URL safely once — guard here so a bad constant is caught at launch, not mid-request.
        guard let url = URL(string: "https://openrouter.ai/api/v1/chat/completions") else {
            fatalError("OpenRouterService: hardcoded endpoint URL is malformed — this is a code error.")
        }
        self.endpointURL = url

        // 120s request timeout: multi-page menus with 3 images can be ~300 KB base64
        // which takes longer than the default 60s on slow connections.
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 120.0
        config.timeoutIntervalForResource = 180.0
        self.session = URLSession(configuration: config)
    }

    // MARK: - GeminiServiceProtocol conformance

    /// Sends a text prompt + optional images to OpenRouter and returns the text response.
    /// Automatically retries on 429 / 5xx with exponential backoff (1s, 2s, 4s).
    func generateContent(
        prompt: String,
        images: [Data] = [],
        model: GeminiModel = .flash,
        responseSchema: String? = nil
    ) async throws -> String {
        guard let apiKey else {
            throw NSError(domain: "OpenRouterService", code: 401,
                          userInfo: [NSLocalizedDescriptionKey: "OpenRouter API key not configured. Check Secrets.xcconfig."])
        }

        let orModel = mapModel(model)
        let body = buildRequestBody(prompt: prompt, images: images, model: orModel, responseSchema: responseSchema)
        let bodyData = try JSONSerialization.data(withJSONObject: body)

        var lastError: Error = NSError(domain: "OpenRouterService", code: -1,
                                       userInfo: [NSLocalizedDescriptionKey: "No attempt made."])

        for attempt in 0..<maxRetries {
            // Exponential backoff: 0s, 1s, 2s (skip sleep on first attempt)
            if attempt > 0 {
                let backoff = UInt64(pow(2.0, Double(attempt - 1)) * 1_000_000_000)
                try? await Task.sleep(nanoseconds: backoff)
            }

            var request = URLRequest(url: endpointURL)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            request.setValue("https://github.com/ChrisZHHG/Nod", forHTTPHeaderField: "HTTP-Referer")
            request.setValue("Nod-iOS", forHTTPHeaderField: "X-Title")
            request.httpBody = bodyData

            do {
                let (data, response) = try await session.data(for: request)
                guard let http = response as? HTTPURLResponse else {
                    throw NSError(domain: "OpenRouterService", code: -1,
                                  userInfo: [NSLocalizedDescriptionKey: "Non-HTTP response received."])
                }

                if http.statusCode == 200 {
                    return try parseResponse(data)
                }

                let errorText = String(data: data, encoding: .utf8) ?? "No error body"
                let error = NSError(domain: "OpenRouterService", code: http.statusCode,
                                    userInfo: [NSLocalizedDescriptionKey: "HTTP \(http.statusCode): \(errorText)"])

                if retryableStatusCodes.contains(http.statusCode) {
                    print("[OpenRouterService] \(http.statusCode) — retrying (\(attempt + 1)/\(maxRetries))...")
                    lastError = error
                    continue
                }
                // Non-retryable (400, 401, 403, etc) — throw immediately.
                throw error

            } catch is CancellationError {
                throw CancellationError()
            } catch {
                // Network-level errors (timeout, no connection) — retry.
                lastError = error
                print("[OpenRouterService] Network error — retrying (\(attempt + 1)/\(maxRetries)): \(error.localizedDescription)")
            }
        }

        throw lastError
    }

    /// Image Generation using OpenRouter (google/imagen-3.0-generate-001).
    /// Falls back to Pollinations.ai if OpenRouter fails or no key is present.
    func generateImage(prompt: String, model: String = "google/imagen-3.0-generate-001") async throws -> URL? {
        print("[OpenRouterService] Generating image via \(model)...")
        
        let augmentedPrompt = "\(prompt), highly detailed food photography, depth of field, natural lighting, bokeh, 8k resolution, photorealistic"
        
        // Try OpenRouter first if we have a key
        if let apiKey = self.apiKey {
            do {
                let body: [String: Any] = [
                    "model": model,
                    "messages": [
                        ["role": "user", "content": augmentedPrompt]
                    ]
                ]
                let bodyData = try JSONSerialization.data(withJSONObject: body)
                
                var request = URLRequest(url: endpointURL)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                request.setValue("https://github.com/ChrisZHHG/Nod", forHTTPHeaderField: "HTTP-Referer")
                request.setValue("Nod-iOS", forHTTPHeaderField: "X-Title")
                request.timeoutInterval = 60.0
                request.httpBody = bodyData
                
                let (data, response) = try await session.data(for: request)
                if let http = response as? HTTPURLResponse, http.statusCode == 200 {
                    let content = try parseResponse(data)
                    // OpenRouter image models typically return markdown `![image](https://...)` or just the URL.
                    // Extract the first http/https URL we find.
                    if let urlString = extractURL(from: content), let url = URL(string: urlString) {
                        return url
                    }
                } else {
                    let errorText = String(data: data, encoding: .utf8) ?? "Unknown Error"
                    print("[OpenRouterService] Image generation failed: \(errorText)")
                }
            } catch {
                print("[OpenRouterService] Error fetching from OpenRouter: \(error)")
            }
        }
        
        // FALLBACK: Pollinations.ai
        print("[OpenRouterService] Falling back to Pollinations.ai...")
        guard let encodedPrompt = augmentedPrompt.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            return nil
        }
        let endpoint = "https://image.pollinations.ai/prompt/\(encodedPrompt)?width=800&height=800&nologo=true&model=flux"
        return URL(string: endpoint)
    }

    // MARK: - Private helpers

    private func buildRequestBody(prompt: String, images: [Data], model: String, responseSchema: String?) -> [String: Any] {
        var contentParts: [[String: Any]] = [["type": "text", "text": prompt]]
        for imageData in images {
            let b64 = imageData.base64EncodedString()
            contentParts.append([
                "type": "image_url",
                "image_url": ["url": "data:image/jpeg;base64,\(b64)"]
            ])
        }
        var body: [String: Any] = [
            "model": model,
            "messages": [["role": "user", "content": contentParts]],
            "temperature": 0.7
        ]
        if responseSchema != nil {
            body["response_format"] = ["type": "json_object"]
        }
        return body
    }

    private func mapModel(_ model: GeminiModel) -> String {
        switch model {
        case .flash: return OpenRouterModel.geminiFlash.rawValue
        case .pro:   return OpenRouterModel.claudeSonnet.rawValue
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
                          userInfo: [NSLocalizedDescriptionKey: "Unexpected API response format. Raw: \(raw.prefix(200))"])
        }

        // Strip markdown code fences if the model wraps JSON in ```json ... ```
        var clean = content.trimmingCharacters(in: .whitespacesAndNewlines)
        if clean.hasPrefix("```json") { clean = String(clean.dropFirst(7)) }
        else if clean.hasPrefix("```")  { clean = String(clean.dropFirst(3)) }
        if clean.hasSuffix("```")       { clean = String(clean.dropLast(3)) }
        return clean.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Helper to extract the first http/https URL from a string (e.g. from markdown `![image](https://...)`)
    private func extractURL(from text: String) -> String? {
        let pattern = "(?i)https?://(?:www\\.)?\\S+(?:/|\\b)"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return nil }
        let nsString = text as NSString
        let results = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
        if let firstMatch = results.first {
            var urlString = nsString.substring(with: firstMatch.range)
            // Clean trailing markdown fragments if regex caught them
            if urlString.hasSuffix(")") { urlString.removeLast() }
            if urlString.hasSuffix("]") { urlString.removeLast() }
            return urlString
        }
        return nil
    }
}
