import Foundation

/// Core strict-type errors for the entire Ambrosia system
enum NodError: Error, Equatable, LocalizedError, Sendable {
    // Pipeline Errors
    case noImagesCaptured
    
    // Core Agent Errors
    case decodingFailed(reason: String)
    case researchFailed(reason: String)
    case recommendationFailed(reason: String)
    
    // Safety Agent Violations
    case safetyVetoTriggered(reason: String)
    
    // Network / API Errors
    case networkFailure(reason: String)
    case apiQuotaExceeded
    case invalidAPIKey
    
    // Generic
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .noImagesCaptured:
            return "No menu images were captured."
        case .decodingFailed(let reason):
            return "Failed to read the menu: \(reason)"
        case .researchFailed(let reason):
            return "Failed to research the restaurant: \(reason)"
        case .recommendationFailed(let reason):
            return "Failed to generate recommendations: \(reason)"
        case .safetyVetoTriggered(let reason):
            return "Safety Alert: \(reason)"
        case .networkFailure(let reason):
            return "Network Error: \(reason)"
        case .apiQuotaExceeded:
            return "API Quota Exceeded. Please try again later."
        case .invalidAPIKey:
            return "Invalid API Key. Please check your settings."
        case .unknown(let msg):
            return "An unknown error occurred: \(msg)"
        }
    }
}
