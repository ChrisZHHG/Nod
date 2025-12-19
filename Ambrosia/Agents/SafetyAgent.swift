import Foundation

// MARK: - Agent C: The Gatekeeper (Safety Agent)

class SafetyAgent {
    private let service: GeminiServiceProtocol
    
    init(service: GeminiServiceProtocol = GeminiService()) {
        self.service = service
    }
    
    /// The Guardrail Prompt
    private func buildAuditPrompt(profile: UserProfile, recommendation: MenuRecommendation) -> String {
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
    
    func audit(draft: MenuRecommendation, context: MenuData, profile: UserProfile) async throws -> MenuRecommendation {
        // Optimization: If no allergies, skip API call to save latency
        if profile.allergies.isEmpty {
            print("[SafetyAgent] 🛡️ No allergies listed. Skipping audit.")
            return draft
        }
        
        print("[SafetyAgent] 🛡️ Auditing recommendation for safety...")
        
        let prompt = buildAuditPrompt(profile: profile, recommendation: draft)
        
        // Call Gemini Flash (Fast Check)
        let jsonString = try await service.generateContent(
            prompt: prompt,
            model: .flash,
            responseSchema: "application/json"
        )
        
        // Parse Audit Result
        struct AuditResult: Decodable {
            let isSafe: Bool
            let violationReason: String?
        }
        
        guard let data = jsonString.data(using: .utf8),
              let result = try? JSONDecoder().decode(AuditResult.self, from: data) else {
            // Fallback: If audit fails to parse, we assume safe but log warning (or fail open depending on policy)
            print("[SafetyAgent] ⚠️ Audit parsing failed. Proceeding with caution.")
            return draft
        }
        
        if !result.isSafe {
            throw NSError(domain: "AmbrosiaSafe", code: 403, userInfo: [
                NSLocalizedDescriptionKey: "Safety Alert: \(result.violationReason ?? "Unknown Safety Risk")"
            ])
        }
        
        print("[SafetyAgent] ✅ Audit Passed.")
        return draft
    }
}
