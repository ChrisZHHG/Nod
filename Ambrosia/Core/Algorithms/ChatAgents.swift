import Foundation

// MARK: - Core/Algorithms/ChatAgents.swift
// Conforms to Principles 4 & 5. 
// Isolated Agents that consume `ChatMessage` protocols and output `ChatMessage` protocols.

final class ModeratorAgent: SoulAgentProtocol {
    private let service: GeminiServiceProtocol
    private let agentName = "Host Moderator"
    
    init(service: GeminiServiceProtocol = OpenRouterService()) {
        self.service = service
    }
    
    func generateChatReply(
        transcript: [ChatMessage],
        soulCommandments: String,
        menuData: MenuData?
    ) async throws -> ChatMessage {
        
        var prompt = "\(soulCommandments)\n\n"
        
        if let menu = menuData {
             if let data = try? JSONEncoder().encode(menu), let str = String(data: data, encoding: .utf8) {
                 prompt += "--- AVAILABLE MENU ---\n\(str)\n\n"
             }
        }
        
        prompt += "--- CONVERSATION HISTORY ---\n"
        
        for msg in transcript {
            prompt += "[\(msg.agentName)]: \(msg.text)\n"
        }
        
        prompt += "\n--- YOUR DIRECTIVE ---\n"
        prompt += "As the Host Moderator, analyze the chat history above. "
        prompt += "If consensus on the required number of safe dishes is reached, output ONLY the JSON: {\"status\":\"consensus\",\"dishes\":[\"Dish1\",\"Dish2\",...]}. "
        prompt += "Otherwise, provide a strict 1-sentence prompt directing the Delegates to continue choosing.\n"
        prompt += "RESPOND WITH YOUR NEXT MESSAGE ONLY:"
        
        // Execute the call using the most intelligent model available (.pro mapping)
        let replyText = try await service.generateContent(
            prompt: prompt,
            model: .pro,
            responseSchema: nil // We want natural language chat, not JSON here.
        )
        
        let consensusReached = ConsensusDetector.isConsensusJSON(replyText)
        return ChatMessage(agentName: self.agentName, text: replyText, isFinalConsensus: consensusReached)
    }
}

final class DelegateAgent: SoulAgentProtocol {
    private let service: GeminiServiceProtocol
    let profile: IndividualProfile
    let delegateName: String
    
    init(service: GeminiServiceProtocol = OpenRouterService(), profile: IndividualProfile, delegateName: String) {
        self.service = service
        self.profile = profile
        self.delegateName = delegateName
    }
    
    func generateChatReply(
        transcript: [ChatMessage],
        soulCommandments: String,
        menuData: MenuData?
    ) async throws -> ChatMessage {
        
        var prompt = "\(soulCommandments)\n\n"
        if let menu = menuData {
             if let data = try? JSONEncoder().encode(menu), let str = String(data: data, encoding: .utf8) {
                 prompt += "--- AVAILABLE MENU ---\n\(str)\n\n"
             }
        }
        
        prompt += "--- CONVERSATION HISTORY ---\n"
        for msg in transcript {
            prompt += "[\(msg.agentName)]: \(msg.text)\n"
        }
        
        let vetoesStr = profile.vetoes.isEmpty ? "None" : profile.vetoes.joined(separator: ", ")
        let cravingsStr = profile.cravings.isEmpty ? "Surprise me" : profile.cravings.joined(separator: ", ")
        
        prompt += "\n--- YOUR DIRECTIVE ---\n"
        prompt += "As \(delegateName), analyze the history. If a proposed dish violates \(vetoesStr), REJECT IT IMMEDIATELY. "
        prompt += "Otherwise, ACCEPT IT or propose a new dish from the menu that fits: \(cravingsStr). "
        prompt += "MAX 2 SENTENCES. NO SMALL TALK. RESPOND WITH YOUR NEXT MESSAGE ONLY:"
        
        // Use a faster, cheaper model for the delegates to simulate rapid fire chatter.
        let replyText = try await service.generateContent(
            prompt: prompt,
            model: .flash, 
            responseSchema: nil
        )
        
        return ChatMessage(agentName: "\(delegateName)'s Agent", text: replyText, isFinalConsensus: false)
    }
}
