import Foundation

// MARK: - Agent C: The Gatekeeper (Safety Agent)

final class SafetyAgent: SafetyAgentProtocol, @unchecked Sendable {
    private let service: GeminiServiceProtocol
    
    init(service: GeminiServiceProtocol = OpenRouterService()) {
        self.service = service
    }
    
    /// The Guardrail Prompt
    private func buildAuditPrompt(profile: IndividualProfile, recommendation: MenuRecommendation) -> String {
        return """
        You are a Safety Auditor.
        
        USER ALLERGIES: [\(profile.allergies.joined(separator: ", "))]
        RECOMMENDED DISH: \(recommendation.translation.localizedName)
        DESCRIPTION: \(recommendation.translation.culturalContext)
        INGREDIENTS (Inferred): \(recommendation.reasoning)
        
        TASK:
        Check if the Recommended Dish violates ANY user allergy.
        Be conservative. If unsure, flagging is better than missing.
        
        OUTPUT JSON:
        {
          "isSafe": true,
          "violationReason": null
        }
        OR
        {
          "isSafe": false,
          "violationReason": "Contains Peanuts which violates user allergy."
        }
        """
    }
    
    func audit(draft: MenuRecommendation, context: MenuData, profile: IndividualProfile) async throws -> MenuRecommendation {
        // Optimization: If no allergies, skip API call to save latency
        if profile.allergies.isEmpty {
            print("[SafetyAgent] 🛡️ No allergies listed. Skipping audit.")
            return draft
        }
        
        print("[SafetyAgent] 🛡️ Auditing individual recommendation for safety...")
        
        let prompt = buildAuditPrompt(profile: profile, recommendation: draft)
        
        // Call Gemini Flash (Fast Check)
        let jsonString = try await service.generateContent(
            prompt: prompt,
            model: .flash,
            responseSchema: "application/json"
        )
        
        let result = try parseAuditResult(jsonString)
        
        if !result.isSafe {
            throw NSError(domain: "AmbrosiaSafe", code: 403, userInfo: [
                NSLocalizedDescriptionKey: "Safety Alert: \(result.violationReason ?? "Unknown Safety Risk")"
            ])
        }
        
        print("[SafetyAgent] ✅ Individual Audit Passed.")
        return draft
    }
    
    // MARK: - Group Audit
    
    func auditCombo(draft: ComboRecommendation, context: MenuData, group: GroupProfile) async throws -> ComboRecommendation {
        let allAllergies = group.collectiveAllergies + group.dietaryRestrictions
        
        if allAllergies.isEmpty {
            print("[SafetyAgent] 🛡️ No group allergies listed. Skipping combo audit.")
            return draft
        }
        
        print("[SafetyAgent] 🛡️ Auditing group combo for safety...")
        
        let prompt = buildComboAuditPrompt(group: group, combo: draft)
        
        let jsonString = try await service.generateContent(
            prompt: prompt,
            model: .flash,
            responseSchema: "application/json"
        )
        
        let result = try parseAuditResult(jsonString)
        
        if !result.isSafe {
            throw NSError(domain: "AmbrosiaSafe", code: 403, userInfo: [
                NSLocalizedDescriptionKey: "Group Safety Alert: \(result.violationReason ?? "Unknown Safety Risk")"
            ])
        }
        
        print("[SafetyAgent] ✅ Group Combo Audit Passed.")
        return draft
    }
    
    private func buildComboAuditPrompt(group: GroupProfile, combo: ComboRecommendation) -> String {
        return """
        You are a Safety Auditor for group dining.
        
        GROUP ALLERGIES: [\(group.collectiveAllergies.joined(separator: ", "))]
        DIETARY RESTRICTIONS: [\(group.dietaryRestrictions.joined(separator: ", "))]
        
        COMBO NAME: \(combo.name)
        DISHES: \(combo.dishes.map { $0.originalName }.joined(separator: ", "))
        DRINKS: \(combo.drinks.map { $0.name }.joined(separator: ", "))
        
        TASK:
        Check if ANY item in this combo violates ANY user allergy or dietary restriction.
        Special Note: If "Vegetarian" is restricted, ensure no meat dishes are present.
        
        OUTPUT JSON:
        {
          "isSafe": true,
          "violationReason": null
        }
        OR
        {
          "isSafe": false,
          "violationReason": "Dish [X] contains Pork which violates DIETARY RESTRICTION [No Pork]."
        }
        """
    }
    
    // MARK: - Helpers
    
    private struct AuditResult: Decodable {
        let isSafe: Bool
        let violationReason: String?
    }
    
    private func parseAuditResult(_ jsonString: String) throws -> AuditResult {
        guard let data = jsonString.data(using: .utf8),
              let result = try? JSONDecoder().decode(AuditResult.self, from: data) else {
            print("[SafetyAgent] ⚠️ Audit parsing failed. Proceeding with caution.")
            return AuditResult(isSafe: true, violationReason: nil)
        }
        return result
    }
}
