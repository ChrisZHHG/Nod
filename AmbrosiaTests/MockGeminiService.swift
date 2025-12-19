import Foundation
@testable import Ambrosia

class MockGeminiService: GeminiServiceProtocol {
    var mockResponse: String?
    var mockImageURL: URL?
    var mockError: Error?
    
    // Advanced Mocking: custom logic based on prompt
    var responseHandler: ((String) -> String)? 
    
    func generateContent(prompt: String, images: [Data], model: GeminiModel, responseSchema: String?) async throws -> String {
        if let error = mockError { throw error }
        
        if let handler = responseHandler {
            return handler(prompt)
        }
        
        return mockResponse ?? "{}"
    }
    
    func generateImage(prompt: String, model: String) async throws -> URL? {
        if let error = mockError { throw error }
        return mockImageURL
    }
}
