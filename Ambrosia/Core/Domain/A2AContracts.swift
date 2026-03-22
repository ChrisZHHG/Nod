import Foundation

// MARK: - A2A Network Protocol & Payload Contracts
// Conforms to Principle 1 & 2: Contract-First & Types as Executable Specifications
// This file must have ZERO dependencies on SwiftUI or MultipeerConnectivity.

/// The strict types of messages that can be broadcasted across the local P2P Lobby.
enum A2AMessageType: String, Codable, Sendable {
    /// Sent when a Delegate first joins the Lobby, silently passing their user profile constraints.
    case joinSignal
    /// Sent by the Host Moderator to all Delegates to inject the rigid `AgentSoul` system prompt and Menu.
    case soulBroadcast
    /// An actual spoken utterance from an LLM Agent in the visible chat.
    case chatMessage
    /// The final, terminating trigger sent by the Host when the 3-dish consensus is locked.
    case consensusReached
    /// Sent by the Host to a newly reconnected peer to restore the full chat transcript.
    case chatHistorySync
    /// Acknowledgement confirming a payload was received (used by B2 message queue).
    case ack
}

/// The universal envelope for all Multipeer JSON transmissions.
struct A2APayload: Codable, Sendable {
    let type: A2AMessageType
    let senderID: UUID
    /// The serialized JSON data specific to the `type` (e.g., encoded `ChatMessage` or `IndividualProfile`).
    let data: Data
    
    init(type: A2AMessageType, senderID: UUID, data: Data) {
        self.type = type
        self.senderID = senderID
        self.data = data
    }
}

// MARK: - Chat Session Types

/// Represents a single conversational turn in the "Spectator Chat".
struct ChatMessage: Codable, Identifiable, Equatable, Hashable, Sendable {
    let id: UUID
    /// The Display Name of the Agent (e.g., "Alice's Agent" or "Host Moderator").
    let agentName: String
    /// The natural language utterance outputted by the LLM.
    let text: String
    /// The UNIX timestamp when the message was generated.
    let timestamp: Date
    /// Flag indicating if this specific message contains the final "[CONSENSUS REACHED]" trigger.
    let isFinalConsensus: Bool
    
    init(id: UUID = UUID(), agentName: String, text: String, timestamp: Date = Date(), isFinalConsensus: Bool = false) {
        self.id = id
        self.agentName = agentName
        self.text = text
        self.timestamp = timestamp
        self.isFinalConsensus = isFinalConsensus
    }
}

/// The initialization package sent by the Host to start the chat.
struct SoulBroadcastPayload: Codable, Sendable {
    /// The name of the restaurant parsed from the menu.
    let restaurantName: String
    /// The OCR'd menu, serialized so Delegates know what food is available.
    let serializedMenuData: Data
    /// The number of dishes the agents must agree upon.
    let requiredDishCount: Int
}

/// Sent by the Host to a reconnected peer to sync the full chat history.
struct ChatHistorySyncPayload: Codable, Sendable {
    let messages: [ChatMessage]
}
