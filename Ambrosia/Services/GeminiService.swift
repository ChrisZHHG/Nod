import Foundation

// MARK: - Service Protocol & Model Enum
//
// These types define the shared contract used by OpenRouterService.
// The old GeminiService actor has been removed — OpenRouterService is the sole implementation.

enum GeminiModel: String {
    /// Fast, cheap, vision-capable — used for most agent calls
    case flash = "google/gemini-2.0-flash-001"
    /// Strong reasoning — used for Moderator and complex tasks
    case pro   = "anthropic/claude-3.5-sonnet:beta"
}

protocol GeminiServiceProtocol: AnyObject, Sendable {
    func generateContent(prompt: String, images: [Data], model: GeminiModel, responseSchema: String?) async throws -> String
    func generateImage(prompt: String, model: String) async throws -> URL?
}

// Convenience defaults so call sites don't need to pass every argument
extension GeminiServiceProtocol {
    func generateContent(
        prompt: String,
        images: [Data] = [],
        model: GeminiModel = .flash,
        responseSchema: String? = nil
    ) async throws -> String {
        try await generateContent(prompt: prompt, images: images, model: model, responseSchema: responseSchema)
    }
}
