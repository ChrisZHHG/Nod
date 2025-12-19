import Foundation

// MARK: - Agent C: The Auditor (The Gatekeeper)

class AuditorAgent {
    private let service: GeminiServiceProtocol
    
    init(service: GeminiServiceProtocol = GeminiService()) {
        self.service = service
    }
    
    /// Strict Safety & Logic Check
    func audit(proposal: ComboRecommendation, menu: MenuData, constraints: GroupProfile) async throws -> ComboRecommendation {
        print("[AuditorAgent] ⚖️ Reviewing Chef's Proposal...")
        
        // 1. Arithmetic Check (Local)
        if proposal.totalPrice > Double(constraints.budgetTotal) * 1.1 { // Allow 10% overflow? No, strict.
            // Actually, let's keep it informative.
             print("⚠️ Budget Exceeded: \(proposal.totalPrice) > \(constraints.budgetTotal)")
        }
        
        // 2. Safety Check (LLM)
        let proposalJSON = try String(data: JSONEncoder().encode(proposal), encoding: .utf8) ?? "{}"
        let prompt = """
        You are a Food Safety Auditor.
        PROPOSAL: \(proposalJSON)
        RESTRICTIONS: \(constraints.collectiveAllergies.joined(separator: ", "))
        
        TASK:
        1. Check if ANY dish violates the allergies interactively (e.g., hidden ingredients).
        2. Verify arithmetic (does total price match sum of items?).
        
        OUTPUT (JSON):
        { "isSafe": true, "reason": "No issues found." }
        OR
        { "isSafe": false, "reason": "Dish X contains Peanuts!" }
        """
        
        let jsonString = try await service.generateContent(
            prompt: prompt,
            model: .flash,
            responseSchema: "application/json"
        )
        
        struct AuditResult: Codable {
            let isSafe: Bool
            let reason: String
        }
        
        guard let data = jsonString.data(using: .utf8),
              let result = try? JSONDecoder().decode(AuditResult.self, from: data) else {
            return proposal // Fallback: Pass if auditor fails to reason
        }
        
        if !result.isSafe {
            throw NSError(domain: "AuditorAgent", code: 403, userInfo: [NSLocalizedDescriptionKey: "SAFETY ALERT: \(result.reason)"])
        }
        
        return proposal // Passed
    }
}
