import Foundation

// MARK: - Agent C: The Gatekeeper (Safety Agent)

final class SafetyAgent: SafetyAgentProtocol, @unchecked Sendable {
    private let service: GeminiServiceProtocol
    
    init(service: GeminiServiceProtocol = OpenRouterService()) {
        self.service = service
    }
    
    /// The Guardrail Prompt
    private func buildAuditPrompt(profile: IndividualProfile, recommendation: SoloRecommendationSet) throws -> String {
        let draftJSON = try String(data: JSONEncoder().encode(recommendation), encoding: .utf8) ?? "{}"
        return """
        You are a Safety Auditor.
        
        USER VETOES (STRICT Avoidance): [\(profile.vetoes.joined(separator: ", "))]
        
        RECOMMENDED SET JSON:
        \(draftJSON)
        
        TASK:
        Check if ANY item in ANY of the 3 options violates ANY user vetoes.
        Be conservative. If unsure, flagging is better than missing.
        
        OUTPUT JSON:
        {
          "isSafe": true,
          "violationReason": null
        }
        OR
        {
          "isSafe": false,
          "violationReason": "In Option A, the dish contains Peanuts which violates user veto."
        }
        """
    }
    
    func audit(draft: SoloRecommendationSet, context: MenuData, profile: IndividualProfile) async throws -> SoloRecommendationSet {
        if profile.vetoes.isEmpty {
            print("[SafetyAgent] 🛡️ No vetoes listed. Skipping individual audit.")
            return draft
        }
        
        print("[SafetyAgent] 🛡️ Auditing all 3 individual recommendations for safety...")
        
        let prompt = try buildAuditPrompt(profile: profile, recommendation: draft)
        
        let jsonString = try await service.generateContent(
            prompt: prompt,
            model: .flash,
            responseSchema: "application/json"
        )
        
        let result = try parseAuditResult(jsonString)
        
        if !result.isSafe {
            throw NodError.safetyAuditFailed(reason: result.violationReason ?? "Unknown Safety Risk")
        }
        
        print("[SafetyAgent] ✅ Individual Set Audit Passed.")
        return draft
    }
    
    // MARK: - Group Audit
    
    func auditCombo(draft: GroupRecommendationSet, context: MenuData, group: GroupProfile) async throws -> GroupRecommendationSet {
        if group.vetoes.isEmpty {
            print("[SafetyAgent] 🛡️ No group vetoes listed. Skipping combo audit.")
            return draft
        }
        
        print("[SafetyAgent] 🛡️ Auditing all 3 group combos for safety...")
        
        let prompt = try buildComboAuditPrompt(group: group, combo: draft)
        
        let jsonString = try await service.generateContent(
            prompt: prompt,
            model: .flash,
            responseSchema: "application/json"
        )
        
        let result = try parseAuditResult(jsonString)
        
        if !result.isSafe {
            throw NodError.safetyAuditFailed(reason: result.violationReason ?? "Unknown Safety Risk")
        }
        
        print("[SafetyAgent] ✅ Group Combos Audit Passed.")
        return draft
    }
    
    private func buildComboAuditPrompt(group: GroupProfile, combo: GroupRecommendationSet) throws -> String {
        let draftJSON = try String(data: JSONEncoder().encode(combo), encoding: .utf8) ?? "{}"
        return """
        You are a Safety Auditor for group dining.
        
        GROUP VETOES (STRICT AVOIDANCE): [\(group.vetoes.joined(separator: ", "))]
        
        RECOMMENDED COMBOS JSON:
        \(draftJSON)
        
        TASK:
        Check if ANY item in ANY of the 3 combos violates ANY group veto.
        Special Note: If "Vegetarian" is restricted/vetoed, ensure meat is avoided.
        
        OUTPUT JSON:
        {
          "isSafe": true,
          "violationReason": null
        }
        OR
        {
          "isSafe": false,
          "violationReason": "In Combo B, Dish [X] contains Pork which violates GROUP VETO [Pork]."
        }
        """
    }
    
    // MARK: - Helpers
    
    private struct AuditResult: Decodable {
        let isSafe: Bool
        let violationReason: String?
    }
    
    private func parseAuditResult(_ jsonString: String) throws -> AuditResult {
        guard let data = jsonString.data(using: .utf8) else {
            throw NodError.safetyAuditFailed(reason: "Safety auditor returned an empty response.")
        }
        
        do {
            return try JSONDecoder().decode(AuditResult.self, from: data)
        } catch {
            print("[SafetyAgent] [ERROR] Audit parsing failed: \(error)")
            // If the auditor fails to return valid JSON, we MUST assume unsafe to be protective.
            throw NodError.safetyAuditFailed(reason: "Safety AI response format was invalid. Please try again.")
        }
    }
}
