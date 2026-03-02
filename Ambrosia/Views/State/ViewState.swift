import Foundation

/// View State UI Contracts

enum AppMode: String, Codable, Equatable, Sendable {
    case individual
    case group
    case agentChat
}

enum AppState: Equatable, Sendable {
    case idle
    case scanning
    case decoding(progress: Double)
    case reasoning(stage: String)
    case verifying
    case error(AmbrosiaError)
}
